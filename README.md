# Deacon: A light-weight Recommend Engine

It's written in Ruby and Sinatra, 
using the idea of collaborative filtering and extract keywords to do simple topic modeling.
See the online demo: 
http://deacon.herokuapp.com/mamibuy/suggest

There are 5 different idea to implement recommendations. 
You can click on any item and see the change on items recommended to you!


## Usage

[SERVER]
ruby ./app.rb

[Console]
irb -r ./app.rb

[RESTART]
touch ./tmp/restart.txt

[DUMP]
filename = 'pageview.csv'
open(filename, 'w') do |f|
  Pageview.all.each do |pv|
    f.puts pv.username.to_s + ',' + pv.usercid + ',' + pv.count.to_s + ',' + pv.url
  end
end

[DATABASE backup]
#### Dump selected database in current path
mongodump --db deacon_api
#### Drop database to clean all
mongo deacon_api --eval "db.dropDatabase()"
#### Recover selected database from assigned path
mongorestore --db deacon_api ./dump/deacon_api/


