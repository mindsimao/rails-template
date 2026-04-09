# Create initial admin user for development
if Rails.env.development?
  User.find_or_create_by!(email: "admin@example.com") do |u|
    u.name = "Admin"
    u.password = "password123"
    u.admin = true
  end
end
