# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
role_types = Role.create([{ name: 'registered' }, { name: 'manager' }, { name: 'admin' },{name: 'grand_manager'},{name: 'operator'},{name: 'bookkeeper'}])
puts 'CREATED ROLE TYPES: ' << role_types.to_s
user = CreateAdminService.new.call
puts 'CREATED ADMIN USER: ' << user.email
product = Product.create(sku: 'test1', title: 'Test1', desc: 'this is test product', quantity: '1', costprice: '100', price: '250')
puts 'CREATED TEST PRODUCT: ' << product.to_s
client = Client.create(name: 'John', surname: 'Weekend', phone: '+71012221314', email: 'john@mail.ru')
puts 'CREATED TEST CLIENT: ' << client.to_s
