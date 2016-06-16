namespace :db do

  task :sync => :environment do
    do_cleanup = ENV['clean'] == 'true'
    changes = SchemaSync.compute_changes(clean: true)
    if changes.empty?
      puts "The schema is up-to-date."
      next
    end
    rs = SchemaSync.random_string(5)
    ms = SchemaSync.build_migrations(changes, {write: false, hash: rs})
    puts "========= Confirm the migration: ========"
    puts ms[:text]
    puts "========================================="
    print "Write changes? [Y/n]: "
    resp = STDIN.gets.chomp
    if resp == "Y" || resp == "y"
      ms = SchemaSync.build_migrations(changes, {write: true, hash: rs})
      fn = ms[:filename]
      puts "Migration written to #{fn}."

      print "Perform migration? [Y/n]: "
      resp = STDIN.gets.chomp
      if resp == "Y" || resp == "y"
        Rake::Task["db:migrate"].invoke
      end
    end
  end

end

