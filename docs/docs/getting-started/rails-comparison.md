---
title: Coming from Ruby on Rails
description: A comparison guide for Rails developers discovering Marten.
sidebar_label: Coming from Rails
---

# Coming from Ruby on Rails

This guide helps Ruby on Rails developers understand Marten by comparing familiar Rails concepts with their Marten equivalents. Marten is heavily inspired by Django (Python), but many patterns will feel natural to Rails developers.

## At a glance

| Concept | Rails | Marten |
|---------|-------|--------|
| Language | Ruby | Crystal |
| Architecture | MVC | Handler/Template (MTV) |
| Controller | `ApplicationController` | `Marten::Handler` |
| Model | `ActiveRecord::Base` | `Marten::DB::Model` |
| View/Template | ERB / Haml | Marten templates (Django-like) |
| Routes | `config/routes.rb` | `config/routes.cr` |
| Migrations | `rails generate migration` | `marten genmigrations` |
| Console | `rails console` | Crystal doesn't have a REPL |
| Package manager | Bundler (Gemfile) | Shards (shard.yml) |
| Test framework | RSpec / Minitest | Crystal spec |
| Background jobs | Sidekiq / Active Job | Not built-in (use custom CLI commands) |

## Project structure

### Rails

```
app/
  controllers/
  models/
  views/
config/
  routes.rb
db/
  migrate/
```

### Marten

```
src/
  handlers/
  models/
  templates/
  apps/           # Optional: group related code
    auth/
      handlers/
      models/
      templates/
config/
  routes.cr
  settings/
    base.cr
    development.cr
    production.cr
```

**Key difference**: Marten uses an optional "apps" system (inspired by Django) to group related models, handlers, and templates. You can also place everything directly in `src/` without apps.

## Models

### Rails

```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  has_many :orders
end
```

### Marten

```crystal
class User < Marten::DB::Model
  field :id, :big_int, primary_key: true, auto: true
  field :email, :string, max_size: 254, unique: true
  field :name, :string, max_size: 100

  with_timestamp_fields  # created_at + updated_at
end
```

**Key differences**:
- Fields are declared explicitly (no magic introspection from database schema)
- Primary key must be declared
- `with_timestamp_fields` replaces `t.timestamps` in migrations
- Validations are tied to fields, not separate `validates` calls

## Queries

| Operation | Rails | Marten |
|-----------|-------|--------|
| All | `User.all` | `User.all` |
| Find by ID | `User.find(1)` | `User.get!(id: 1)` |
| Find or nil | `User.find_by(email: "a@b.c")` | `User.get(email: "a@b.c")` |
| Where | `User.where(active: true)` | `User.filter(active: true)` |
| Order | `User.order(:name)` | `User.all.order(:name)` |
| Count | `User.count` | `User.all.count` |
| Exists? | `User.exists?(email: "a@b.c")` | `User.filter(email: "a@b.c").exists?` |
| Create | `User.create!(email: "a@b.c")` | `u = User.new; u.email = "a@b.c"; u.save!` |
| Update | `user.update!(name: "New")` | `user.name = "New"; user.save!` |
| Delete | `user.destroy` | `user.delete` |

### Advanced queries

```crystal
# Marten uses q() for complex lookups
User.filter { q(email__icontains: "example") & q(active: true) }
User.filter { q(created_at__gte: 1.day.ago) }
```

## Controllers → Handlers

### Rails

```ruby
class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user
    else
      render :new
    end
  end
end
```

### Marten

```crystal
class UserDetailHandler < Marten::Handler
  def get
    user = User.get!(id: params["id"])
    render "users/detail.html", context: {user: user}
  end
end

class UserCreateHandler < Marten::Handlers::Schema
  schema UserSchema
  template_name "users/new.html"

  after_successful_schema_validation :create_user

  private def create_user
    user = User.new
    user.email = schema.email
    user.save!
    @response = redirect(reverse("user_detail", id: user.id!))
  end
end
```

**Key differences**:
- One handler per action (not one controller with many actions)
- `Marten::Handler` for simple GET/POST
- `Marten::Handlers::Schema` for form handling (like Rails strong params + form objects)
- Templates are explicit, not convention-based
- `render` returns an `HTTP::Response`

## Routes

### Rails

```ruby
Rails.application.routes.draw do
  resources :users
  get "about", to: "pages#about"
end
```

### Marten

```crystal
Marten.routes.draw do
  path "/users", UsersHandler, name: "users"
  path "/users/<id:int>", UserDetailHandler, name: "user_detail"
  path "/about", AboutHandler, name: "about"

  # Namespaced routes (like Rails scope/namespace)
  path "/admin", Admin::ROUTES, name: "admin"
end
```

**Key differences**:
- No `resources` shortcut — each route is explicit
- URL parameters use `<name:type>` syntax
- Named routes with `name:` (used in templates with `{% url 'name' %}`)
- Route groups via separate route maps (like `Admin::ROUTES`)

## Templates

### Rails (ERB)

```erb
<h1><%= @user.name %></h1>
<% if @user.admin? %>
  <span>Admin</span>
<% end %>
<%= link_to "Edit", edit_user_path(@user) %>
```

### Marten

```html
<h1>{{ user.name }}</h1>
{% if user.admin? %}
  <span>Admin</span>
{% endif %}
<a href="{% url 'user_edit' id: user.pk %}">Edit</a>
```

**Key differences**:
- Django-style `{{ }}` for output, `{% %}` for logic
- No Ruby code in templates — only template tags and filters
- `{% url %}` instead of `_path` helpers
- `{% extend %}` and `{% block %}` for template inheritance (instead of `yield` / `content_for`)
- Use `&&` / `||` operators (not `and` / `or`)

## Migrations

### Rails

```bash
rails generate migration AddEmailToUsers email:string
rails db:migrate
```

### Marten

```bash
# Marten auto-generates migrations from model changes
marten genmigrations
marten migrate
```

**Key difference**: Marten auto-detects model changes and generates migrations automatically (like Django's `makemigrations`). No need to write migrations manually for simple field additions.

## Sessions and authentication

### Rails

```ruby
session[:user_id] = user.id
current_user  # via Devise or custom concern
```

### Marten

```crystal
# With marten_auth shard
MartenAuth.sign_in(request, user)
request.user  # returns the authenticated user or nil
```

**Key differences**:
- Authentication via the `marten_auth` shard (not built into core)
- Session data stored in cookies by default (configurable)
- `request.user` instead of `current_user`
- ⚠️ `sign_in` may flush the session — save important session data before calling it

## Email

### Rails

```ruby
class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: user.email, subject: "Welcome!")
  end
end
```

### Marten

```crystal
class WelcomeEmail < Marten::Email
  to @user.email!
  subject "Welcome!"
  template_name "emails/welcome.html"

  def initialize(@user : User)
  end

  def context
    Marten::Template::Context{"name" => @user.name}
  end
end

# Send
WelcomeEmail.new(user).deliver
```

## Environment configuration

### Rails

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.force_ssl = true
end
```

### Marten

```crystal
# config/settings/production.cr
Marten.configure :production do |config|
  config.debug = false
  config.allowed_hosts = ["myapp.com"]
end
```

**Key difference**: Marten uses `MARTEN_ENV` environment variable (like `RAILS_ENV`).

## CLI commands

| Task | Rails | Marten |
|------|-------|--------|
| New project | `rails new myapp` | `marten new project myapp` |
| Dev server | `rails server` | `marten serve` |
| Migrations | `rails db:migrate` | `marten migrate` |
| Generate migration | `rails g migration` | `marten genmigrations` |
| Console | `rails console` | *(not available)* |
| Routes | `rails routes` | `marten routes` |
| New app | *(not needed)* | `marten new app myapp` |
| Custom command | `rails runner` | Custom CLI command class |

### Custom CLI commands

```crystal
class MyTask < Marten::CLI::Command
  command_name :my_task
  help "Does something useful."

  def run
    puts "Running..."
  end
end

# Run with: marten my_task
```

## Common gotchas for Rails developers

1. **No implicit rendering**: You must explicitly call `render` — there's no convention-based template lookup
2. **No strong params**: Use `Marten::Schema` for form validation and data extraction
3. **Templates are not Ruby**: No arbitrary code execution in templates — use template tags and filters
4. **One handler = one action**: Unlike Rails controllers, each handler typically handles one endpoint
5. **Fields are explicit**: All model fields must be declared — no schema introspection
6. **`request.user` in templates**: Don't access `request.user.email` directly in templates — pass variables through the handler context to avoid potential issues
7. **Hash in templates**: `Hash(String, String)` keys are accessible as template attributes (e.g., `{{ item.my_key }}`)
8. **Session flush on sign_in**: `MartenAuth.sign_in` may flush the session. Save important data (like cart contents) before calling it
