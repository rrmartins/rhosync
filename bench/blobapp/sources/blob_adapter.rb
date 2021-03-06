# require 'fileutils' # FIXME:

class BlobAdapter < SourceAdapter
  def initialize(source) 
    super(source)
  end
 
  def login
    # TODO: Login to your data source here if necessary
    true
  end
 
  def query(params=nil)
    Store.lock(lock_name,1) do
      @result = Store.get_data(db_name)
    end
    @result   
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash)
    file_name = create_hash['filename']    
    if file_name
      # Copy image to file system
      # FileUtils.copy_file(path_to_img_file, "/Users/alexb/workspace/tmp/#{file_name}") # FIXME:
      
      # Simple verification that image successfully uploaded 
      file = File.join(File.dirname(__FILE__), '..', '..', 'lib', 'testdata', 'images', file_name)
      path_to_img_file = create_hash['image_uri']
      expected_size, actual_size = File.size(file), File.size(path_to_img_file) 
      raise "BlobAdapter#create: expected image size #{expected_size}, but actual is #{actual_size}" if expected_size != actual_size

      # Adjust create_hash to match expected md 
      create_hash['img_file-rhoblob'] = file_name
      create_hash.delete('image_uri')   
    end

    id = create_hash['mock_id']
    Store.lock(lock_name,1) do
      Store.put_data(db_name,{id => create_hash}, true) if id
    end
    id
  end
 
  def update(update_hash)
    # TODO: Update an existing record in your backend data source
    raise "Please provide some code to update a single record in the backend data source using the update_hash"
  end
 
  def delete(delete_hash)
    # TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the object_id"
  end
 
  def logoff
    # TODO: Logout from the data source if necessary
  end

  private
  
  def db_name
    "test_db_storage:#{@source.app_id}:#{@source.user_id}"
  end
  
  def lock_name
    "lock:#{db_name}"
  end

end