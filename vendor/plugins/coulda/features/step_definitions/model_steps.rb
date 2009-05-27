# GENERATION

When /^I generate a model named "(.*)"$/ do |model|
  system "cd #{@rails_root} && " <<
         "script/generate model #{model} && " <<
         "cd .."
end

When /^I generate a model "(.*)" with a (.*) "(.*)"$/ do |model, attr_type, attr_name|
  system "cd #{@rails_root} && " <<
         "script/generate model #{model} #{attr_name}:#{attr_type} && " <<
         "cd .."
end

When /^I generate a model "(.*)" that belongs to a "(.*)"$/ do |model, association|
  association.downcase!
  system "cd #{@rails_root} && " <<
         "script/generate model #{model} #{association}:belongs_to && " <<
         "cd .."
end

When /^I generate a model "(.*)" with file "(.*)"$/ do |model, file|
  file.downcase!
  system "cd #{@rails_root} && " <<
         "script/generate model #{model} #{file}:paperclip && " <<
         "cd .."
end

# MODEL

Then /^a model with comments should be generated for "(.*)"$/ do |model|
  model.downcase!
  assert_generated_model_for(model) do |body|
    comments = []
    comments << "# includes: mixed in behavior" <<
                "# properties: attributes, associations" <<
                "# lifecycle: validations, callbacks" <<
                "# class methods: self.method, named_scopes" <<
                "# instance methods" <<
                "# non-public interface: protected helpers"
    comments.each do |comment|
      assert body.include?(comment), body.inspect
    end
  end
end

Then /^the "(.*)" model should have "(.*)" macro$/ do |model, macro|
  model.downcase!
  assert_generated_model_for(model) do |body|
    assert body.include?(macro), body.inspect
  end
end

# FACTORY

Then /^a factory should be generated for "(.*)"$/ do |model|
  model.downcase!
  assert_generated_factory_for(model) do |body|
    expected = "Factory.define :#{model.downcase} do |#{model.downcase}|\n" <<
               "end\n"
    assert_equal expected, body
  end
end

Then /^a factory for "(.*)" should have an? "(.*)" (.*)$/ do |model, attr_name, attr_type|
  model.downcase!
  assert_generated_factory_for(model) do |body|
    expected = "Factory.define :#{model} do |#{model}|\n" <<
               "  #{model}.#{attr_name} { '#{attr_type}' }\n" <<
               "end\n"
    assert_equal expected, body
  end
end

Then /^a factory for "(.*)" should have an association to "(.*)"$/ do |model, associated_model|
  model.downcase!
  associated_model.downcase!
  assert_generated_factory_for(model) do |body|
    expected = "Factory.define :#{model} do |#{model}|\n" <<
               "  #{model}.association(:#{associated_model})\n" <<
               "end\n"
    assert_equal expected, body
  end
end

# UNIT TEST

Then /^a unit test should be generated for "(.*)"$/ do |model|
  model.downcase!
  assert_generated_unit_test_for(model) do |body|
    match = "assert_valid Factory.build(:#{model})"
    assert body.include?(match), body.inspect
  end
end

Then /^the "(.*)" unit test should have "(.*)" macro$/ do |model, macro|
  model.downcase!
  assert_generated_unit_test_for(model) do |body|
    assert body.include?(macro), body.inspect
  end
end

# MIGRATION

Then /^the "(.*)" table should have db index on "(.*)"$/ do |table, foreign_key|
  assert_generated_migration(table) do |body|
    index = "add_index :#{table}, :#{foreign_key}"
    assert body.include?(index), body.inspect
  end
end

Then /^the "(.*)" table should have paperclip columns for "(.*)"$/ do |table, attr|
  up   = "      table.string :#{attr}_file_name\n"  <<
         "      table.string :#{attr}_content_type\n"  <<
         "      table.integer :#{attr}_file_size\n" <<
         "      table.datetime :#{attr}_updated_at"
  assert_generated_migration(table) do |body|
    assert body.include?(up), body.inspect
  end
end


