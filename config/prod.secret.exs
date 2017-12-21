use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :ucx_ucc, UcxUccWeb.Endpoint,
  secret_key_base: "Z9j5A+lDlf1qG+i2ZhVavb0GKHDLkZb/MH7qVy95FM8s2T0d3AI7WU6gyWipUxVl"

# Configure your database
config :ucx_ucc, UcxUcc.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "Gt5de3aq1",
  database: "ucx_ucc_prod",
  pool_size: 15
