## sluggable_finder

Ismael Celis 

http://github.com/ismasan/sluggable_finder

This gem is originally based on http://github.com/smtlaissezfaire/acts_as_sluggable/tree/master/lib%2Facts_as_slugable.rb

## DESCRIPTION:

This is a variation of acts_as_sluggable, permalink_fu and acts_as_permalink. 
This plugin allows models to generate a unique "slug" (url-enabled name) from any regular attribute.
Sluggable models can have a scope parameter so slugs are unique relative to a parent model.

The plugin intercepts ActiveRecord::Base.find to look into the slug field if passed a single string as an argument. It works as normal if you pass an integer or more finder parameters.

The plugin modifies to_param so it's transparent to link_to and url_for view helpers

## FEATURES/PROBLEMS:

Slugs are created when a model is created. Subsequent changes to the source field will not modify the slug unless you specifically change the value of the slug field. This is because permalinks should never change.

Complete specs. To test, make sure you create an empty SQLite database file in spec/db/test.db

Then run the following to load the test schema:

rake db:create

## SYNOPSIS:

### Models
    class Category < ActiveRecord::Base
		has_many :posts
		sluggable_finder :title #slugifies the :title field into the :slug field
	end

	class Post < ActiveRecord::Base
		belongs_to :category
		has_many :comments
		sluggable_finder :title, :scope => :category_id #Post slugs are unique to the parent category
	end

	class Comment < ActiveRecord::Base
		belongs_to :post
		sluggable_finder :get_slug, :to => :permalink #creates slug from custom attribute and stores it in "permalink" field

		def get_slug #we define the custom attribute
			"#{post.id}-#{Time.now}"
		end
	end

	# Provide a list or reserved slugs you don't want available as permalinks
	#
	sluggable_finder :title, :reserved_slugs => %w(admin settings users)

### Controllers

You can do Model.find(slug) just how you would with a single numerical ID. It will also raise a RecordNotFound exception so you can handle that in your application controller.
The idea is that you keep your controller actions clean and handle Not Found errors elsewhere. You can still use Model.find the regular way.

    class PostsController < ApplicationController
        # params[:id] is a string, URL-encoded slug
		def show
			@post = Post.find( params[:id] ) #raises ActiveRecord::RecordNotFound if not found
		end  
	end

### Merb and custom NotFound exception

In merb it would be nice to raise a NotFound exception instead of ActiveRecord's RecordNotFoundm so we don't need to clutter our controller with exception-handling code and we let the framework handle them.

   	SluggableFinder.not_found_exception = Merb::ControllerExceptions::NotFound

You can configure this to raise any exception you want.

    class CustomException < StandardError; end

    SluggableFinder.not_found_exception = CustomException

### Links

Link generation remains the same, because the plugin overwrites your model's to_param method

    <%= link_to h(@post.title), @post %> # => <a href="/posts/hello-world">Hello world</a>

## REQUIREMENTS:

ActiveRecord, ActiveSupport

## INSTALL:

If you haven't yet, add github.com to your gem sources (you only need to do that once):

    gem sources -a http://gems.github.com

Now you can install the normal way:

    sudo gem install ismasan-sluggable_finder

Then, in your Rails app's environment:

    config.gem "ismasan-sluggable_finder", :lib => 'sluggable_finder'

If you wan to unpack the gem to you app's "vendor" directory:

    rake gems:unpack

## TODO:

*Refactor. It works but I hate the code.

## LICENSE:

(The MIT License)

Copyright (c) 2008 Ismael Celis

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.