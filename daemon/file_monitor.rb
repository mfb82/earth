class FileMonitor
  cattr_accessor :log_all_sql
  
  # Set this to true if you want to see the individual SQL commands
  self.log_all_sql = false
  
  def FileMonitor.run_on_new_directory(path, update_time)
    this_server = Earth::Server.this_server
    puts "WARNING: Watching new directory. So, clearing out database"
    this_server.directories.clear      
    directory = this_server.directories.create(:name => File.expand_path(path))
    run(directory, update_time)
  end
  
  def FileMonitor.run_on_existing_directory(update_time)
    directories = Earth::Directory.roots_for_server(Earth::Server.this_server)
    raise "Watch directory is not set for this server" if directories.empty?
    raise "Currently not properly supporting multiple watch directories" if directories.size > 1
    directory = directories[0]
    puts "Collecting startup data from database..."
    directory.load_all_children
    run(directory, update_time)
  end
  
private

  def FileMonitor.run(directory, update_time)
    puts "Watching directory #{directory.path}"
    while true do
      puts "Updating..."
      update(directory)
      puts "Sleeping for #{update_time} seconds..."
      sleep(update_time)
    end
  end
  
  def FileMonitor.update(directory)
    directory.each do |d|
      update_non_recursive(d)
    end
  end

  def FileMonitor.update_non_recursive(directory)
    # TODO: remove exist? call as it is an extra filesystem access
    if File.exist?(directory.path)
      new_directory_stat = File.lstat(directory.path)
    else
      new_directory_stat = nil
    end
    
    # If directory hasn't changed then return
    if new_directory_stat == directory.stat
      return
    end

    file_names, subdirectory_names, stats = [], [], Hash.new
    if new_directory_stat && new_directory_stat.readable? && new_directory_stat.executable?
      file_names, subdirectory_names, stats = contents(directory)
    end

    added_directory_names = subdirectory_names - directory.children.map{|x| x.name}
    added_directory_names.each do |name|
    
      dir = Earth::Directory.benchmark("Creating directory with name #{name}", Logger::DEBUG, !log_all_sql) do 
        directory.child_create(:name => name)
      end
      update_non_recursive(dir)
    end

    # By adding and removing files on the association, the cache of the association will be kept up to date
    added_file_names = file_names - directory.files.map{|x| x.name}
    added_file_names.each do |name|
      Earth::File.benchmark("Creating file with name #{name}", Logger::DEBUG, !log_all_sql) do
        directory.files.create(:name => name, :stat => stats[name])
      end
    end

    directory.files.each do |file|
      # If the file still exists
      if file_names.include?(file.name)
        # If the file has changed
        if file.stat != stats[file.name]
          file.stat = stats[file.name]
          Earth::File.benchmark("Updating file with name #{file.name}", Logger::DEBUG, !log_all_sql) do
            file.save
          end
        end
      # If the file has been deleted
      else
        Earth::Directory.benchmark("Removing file with name #{file.name}", Logger::DEBUG, !log_all_sql) do
          directory.files.delete(file)
        end
      end
    end
    
    directory.children.each do |dir|
      # If the directory has been deleted
      if !subdirectory_names.include?(dir.name)
        Earth::Directory.benchmark("Removing directory with name #{dir.name}", Logger::DEBUG, !log_all_sql) do
          directory.child_delete(dir)
        end
      end
    end
    
    # Update the directory stat information at the end
    if File.exist?(directory.path)
      directory.stat = new_directory_stat
      # This will not overwrite 'lft' and 'rgt' so it doesn't matter if these are out of date
      Earth::Directory.benchmark("Updating directory with name #{directory.name}", Logger::DEBUG, !log_all_sql) do
        directory.update
      end
    end
  end

  def FileMonitor.contents(directory)
    entries = Dir.entries(directory.path)
    # Ignore ".' and ".." directories
    entries.delete(".")
    entries.delete("..")
    
    # Contains the stat information for both files and directories
    stats = Hash.new
    entries.each {|x| stats[x] = File.lstat(File.join(directory.path, x))}
  
    # Seperately test for whether it's a file or a directory because it could
    # be something like a symbolic link (which we shouldn't follow)
    file_names = entries.select{|x| stats[x].file?}
    subdirectory_names = entries.select{|x| stats[x].directory?}
    
    return file_names, subdirectory_names, stats
  end
end
