class FixedSchemaAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
  
  def query(params=nil)
    @result = Store.get_data('test_db_storage')
  end
end