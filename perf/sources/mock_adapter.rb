class MockAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    true
  end
 
  def query(params=nil)
    Store.lock(lock_name,1) do
      @result = Store.get_data(db_name)
    end
    @result
  end
  
  def create(name_value_list,blob=nil)
    id = name_value_list.delete('id')
    Store.lock(lock_name,1) do
      Store.put_data(db_name,{id=>name_value_list},true) if id
    end
    id
  end
 
  def update(name_value_list)
    id = name_value_list.delete('id')
    return unless id
    Store.lock(lock_name,1) do
      data = Store.get_data(db_name)
      return unless data and data[id]
      name_value_list.each do |attrib,value|
        data[id][attrib] = value
      end
      Store.put_data(db_name,data)
    end
  end
 
  def delete(name_value_list)
    id = name_value_list.delete('id')
    Store.lock(lock_name,1) do
      Store.delete_data(db_name,{id=>name_value_list}) if id
    end
  end
 
  def db_name
    "test_db_storage:#{@source.app_id}:#{@source.user_id}"
  end
  
  def lock_name()
    "#{db_name}:lock"
  end
  
  private
  
end