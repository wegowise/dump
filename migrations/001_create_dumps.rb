Sequel.migration do
  change do
    create_table(:dumps) do
      primary_key :id
      String :key, null: false
      File :body, null: false
      Time :created_at, null: false
    end
  end
end
