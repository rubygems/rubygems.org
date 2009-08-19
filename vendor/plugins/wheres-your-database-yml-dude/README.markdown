# [Where's your database.yml, dude?](http://www.youtube.com/watch?v=d1wuijgeaaY)

<object width="425" height="344"><param name="movie" value="http://www.youtube.com/v/d1wuijgeaaY&hl=en&fs=1&"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/d1wuijgeaaY&hl=en&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>

In rails apps, it is considered a good practice to not include config/database.yml under version control. Developers might have different settings, ie someone prefers mysql, or postgres, or even sqlite3. It's also bad to have production passwords in it, so many projects will copy an appropriate database.yml in at deploy time.

So if database.yml isn't in version control, then where is it?

wheres-your-database-yml-dude answers this question. It hooks into rails' rake tasks to make sure a database.yml when its needed. Additionally, if you have a config/database.yml.example, it'll copy that in place for you.


To get started, go something like this (assuming you are using git, and have database.yml checked in currently):

    script/plugin install git://github.com/technicalpickles/wheres-your-database-yml-dude
    git mv config/database.yml config/database.yml.example
    ${EDITOR} config/database.yml.example # make it nice and clean, and free of passwords
    echo config/database.yml >> .gitignore
    git add vendor/plugins/wheres-your-database-yml-dude .gitignore config
    git commit -m "Where's your database.yml, dude?"

