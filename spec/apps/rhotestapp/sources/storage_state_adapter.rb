class StorageStateAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    true
  end
 
  def query
    @result
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    @source.app.store.put_data('storage_state_adapter',{'1'=>name_value_list})
    '1'
  end
 
  def update(name_value_list)
  end
 
  def delete(name_value_list)
  end
 
  def logoff
  end
end