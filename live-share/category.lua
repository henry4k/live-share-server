local db = require'live-share.database'


local category = {}

function category.create(name)
    db('INSERT INTO category (name) VALUES (?)', name)
    return db.last_id()
end

function category.get_by_name(name)
    local row = db('SELECT id FROM category WHERE name = ?', name):fetch()
    if row then return row[1] end
end

function category.get_or_create(name)
    return category.get_by_name(name) or category.create(name)
end

return category
