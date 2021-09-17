class Dog
    attr_accessor :name, :breed, :id

    def initialize(attributes)
        attributes.each {|key, value| self.send(("#{key}="), value)}
        self.id ||= nil
    end

    def self.create_table
        sql = <<-SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
        )
    SQL

    DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
        DROP TABLE dogs
        SQL

        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?,?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0] [0]
        end
        self
    end

    def self.create(attributes)
        dog = Dog.new(attributes)
        dog.save
        dog
    end

    def self.new_from_db(row)
        attributes = {
            :id => row[0],
            :name => row[1],
            :breed => row[2]
          }
          Dog.new(attributes)
    end

    def self.find_by_id(id)
        sql = "SELECT * FROM dogs WHERE id = ?"
        DB[:conn].execute(sql, id).map { |row| self.new_from_db(row) }.first
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM dogs WHERE name = ?
        SQL

        DB[:conn].execute(sql, name).map do |row|
        self.new_from_db(row)
        end.first
    end


    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE name = ? AND breed = ?
        SQL

        dogs = DB[:conn].execute(sql, name, breed).first

        if dogs 
            dog_1 = self.new_from_db(dogs)
        else
            dog_1 = self.create({:name => name, :breed => breed})
        end
        dog_1
    end
        
    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?;"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end
end
