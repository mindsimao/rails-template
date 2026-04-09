# Controller & Model Design Patterns

This document describes Fizzy's approach to keeping controllers thin and building a rich domain model.

## Philosophy

Controllers are **coordination layers** that authenticate, authorize, call 1-2 model methods, and render responses. Business logic lives in models, organized through concerns and intention-revealing APIs.

## Core Patterns

### 1. Intention-Revealing Model APIs

Controllers call expressive, domain-meaningful methods rather than implementing logic directly.

**Good:**
```ruby
# Cards::GoldnessesController
def create
  @card.gild
  respond_to { |format| format.turbo_stream { render_card_replacement } }
end

# Cards::ClosuresController
def create
  @card.close(user: Current.user)
  # ...
end
```

**Implementation lives in model concerns:**
```ruby
# app/models/card/golden.rb
def gild
  create_goldness! unless golden?
end

# app/models/card/closeable.rb
def close(user: Current.user)
  transaction do
    create_closure! user: user
    track_event :closed, creator: user
  end
end
```

**More examples from the codebase:**
- `@card.watch_by(user)` / `@card.unwatch_by(user)`
- `@card.toggle_assignment(user)`
- `@card.triage_into(column)`
- `@board.publish` / `@board.unpublish`
- `@user.deactivate`

### 2. Plain Active Record When Appropriate

Don't over-engineer simple operations. Direct Active Record calls are fine.

```ruby
# Cards::CommentsController
def create
  @comment = @card.comments.create!(comment_params)
end

def update
  @comment.update! comment_params
end
```

### 3. Model Operations as Resources (Not Custom Actions)

Complex operations are modeled as separate resource controllers with CRUD actions.

**Good:**
```ruby
# config/routes.rb
resources :cards do
  resource :closure      # create = close, destroy = reopen
  resource :goldness     # create = gild, destroy = ungild
  resource :watch        # create = watch, destroy = unwatch
end
```

**Bad:**
```ruby
resources :cards do
  post :close
  post :reopen
  post :gild
  post :ungild
end
```

### 4. Model Concerns for Cohesive Functionality

Extract business logic into focused concerns, one aspect per concern.

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  include Closeable, Watchable, Triageable, Assignable, Golden, Taggable
  # Each concern handles one domain aspect
end
```

**Concern structure:**
```ruby
# app/models/card/closeable.rb
module Card::Closeable
  extend ActiveSupport::Concern

  def close(user: Current.user)
    unless closed?
      transaction do
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  def reopen(user: Current.user)
    if closed?
      transaction do
        closure&.destroy
        track_event :reopened, creator: user
      end
    end
  end
end
```

### 5. Controller Concerns for Shared Setup

Extract repeated controller setup into concerns to eliminate boilerplate.

```ruby
# app/controllers/concerns/card_scoped.rb
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(...)
    end
end
```

**Usage in controllers:**
```ruby
class Cards::CommentsController < ApplicationController
  include CardScoped  # Automatically sets @card, @board

  def create
    @comment = @card.comments.create!(comment_params)
  end
end
```

### 6. Form Objects for Complex Workflows

Multi-step operations use form objects (ActiveModel, not ActiveRecord) that encapsulate validation and orchestration.

```ruby
# app/models/signup.rb
class Signup
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :identity_creation
  validates :full_name, :identity, presence: true, on: :completion

  def create_identity
    @identity = Identity.find_or_create_by!(email_address: email_address)
    @identity.send_magic_link for: :sign_up
  end

  def complete
    if valid?(:completion)
      @tenant = create_tenant
      create_account
    end
  end
end
```

**Controller stays thin:**
```ruby
# app/controllers/signups_controller.rb
def create
  signup = Signup.new(signup_params)
  if signup.valid?(:identity_creation)
    redirect_to_session_magic_link signup.create_identity
  else
    head :unprocessable_entity
  end
end
```

### 7. Async Operations: `_later` / `_now` Convention

Model methods that have both sync and async versions follow this naming pattern.

```ruby
# app/models/account/export.rb
def build_later
  ExportAccountDataJob.perform_later(self)
end

def build  # Called by job
  processing!
  zipfile = generate_zip
  file.attach io: File.open(zipfile.path)
  mark_completed
  ExportMailer.completed(self).deliver_later
end
```

**Controller:**
```ruby
def create
  Current.account.exports.create!(user: Current.user).build_later
  redirect_to account_settings_path, notice: "Export started"
end
```

**Event relaying pattern (common):**
```ruby
# app/models/concerns/event/relaying.rb
included do
  after_create_commit :relay_later
end

def relay_later
  Event::RelayJob.perform_later(self)
end

def relay_now
  # Actual relay logic
end

# app/jobs/event/relay_job.rb
class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

### 8. Rich Association Extensions

Complex operations on associations are defined as association extensions.

```ruby
# app/models/board/accessible.rb
has_many :accesses, dependent: :delete_all do
  def revise(granted: [], revoked: [])
    transaction do
      grant_to granted
      revoke_from revoked
    end
  end

  def grant_to(users)
    Access.insert_all Array(users).collect { ... }
  end

  def revoke_from(users)
    destroy_by user: users unless proxy_association.owner.all_access?
  end
end
```

**Controller:**
```ruby
def update
  @board.update! board_params
  @board.accesses.revise(granted: grantees, revoked: revokees) if grantees_changed?
end
```

### 9. Class Methods for Complex Creation

Complex object creation is encapsulated in class methods.

```ruby
# app/models/account.rb
class << self
  def create_with_owner(account:, owner:)
    create!(**account).tap do |account|
      account.users.create!(role: :system, name: "System")
      account.users.create!(**owner.reverse_merge(role: "owner", verified_at: Time.current))
    end
  end
end
```

### 10. Model Scopes for Query Logic

Keep query logic in models via scopes. Controllers chain scopes.

```ruby
# app/models/notification.rb
scope :unread, -> { where(read_at: nil) }
scope :read, -> { where.not(read_at: nil) }
scope :ordered, -> { order(read_at: :desc, created_at: :desc) }

def self.read_all
  unread.update_all(read_at: Time.current)
end
```

**Controller:**
```ruby
def create
  Current.user.notifications.unread.read_all
end
```

## Quick Reference

When writing new code:

1. **Controllers should:**
   - Authenticate and authorize
   - Call 1-2 intention-revealing model methods
   - Render responses
   - Be 5-20 lines per action (typically)

2. **Models should:**
   - Contain all business logic
   - Use concerns for different aspects (Closeable, Watchable, etc.)
   - Provide expressive APIs (`gild`, `triage_into`, `deactivate`)
   - Use scopes for query logic
   - Use class methods for complex creation

3. **Use form objects when:**
   - Multi-step workflows with distinct validation phases
   - Complex orchestration across multiple models
   - Non-CRUD operations that don't map to a single model

4. **Model complex operations as resources when:**
   - The operation is significant enough to be its own thing
   - You'd otherwise add custom actions to a controller
   - It keeps your routes RESTful

## Examples to Study

Good controller examples:
- `app/controllers/cards/goldnesses_controller.rb` - Simple resource pattern
- `app/controllers/cards/closures_controller.rb` - Stateful transitions
- `app/controllers/boards_controller.rb` - Complex update with association revision
- `app/controllers/signups_controller.rb` - Form object usage

Good model concern examples:
- `app/models/card/closeable.rb` - Clean state transitions
- `app/models/card/triageable.rb` - Workflow logic
- `app/models/board/accessible.rb` - Association extensions
- `app/models/concerns/event/relaying.rb` - Async pattern
