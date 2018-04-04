defmodule OnePages.TestHelpers do

  def strip_ts(schema) do
    struct schema, inserted_at: nil, updated_at: nil
  end

  def schema_eq(schema1, schema2) do
    strip_ts(schema1) == strip_ts(schema2)
  end

end
