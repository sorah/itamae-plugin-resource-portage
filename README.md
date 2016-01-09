# Itamae::Plugin::Resource::Portage

## Installation

```ruby
gem 'itamae-plugin-resource-portage'
```

## prerequisites

- eix

## Usage

### Basic attributes

All resources take `name`, `slot`, `version`, and/or `atom` attribtues

- name (default_name): package name (category/name)
- version (+ slot) or atom:
  - version: package version + operator (e.g. `1.0.0`, `>=1.0.0`, `<2.0.0`)
  - slot: (optional)
  - atom: if specified, version and slot are ignored

`portage_accept_keywords`, `portage_mask`, `portage_unmask`, `portage_use` resource take additionally:

- action: `:add` (default) or `:remove`
- target: when absolute path given, the resource will use that path to modify (e.g. `/etc/portage/package.use/foobar`). Otherwise, given name under appropriate directory will be used (e.g. `foobar` to `/etc/portage/package.XXX/foobar`); Default to `/etc/portage/package.XXX/itamae` or `/etc/portage/package.XXX` (only when it exists as file)


### `portage` resource

`portage` resource defines `portage_package`, `portage_unmask`, `portage_accept_keywords`, `portage_use`, and/or `portage_pin` resources based on given attributes.

```
portage "www-servers/nginx" do
end

portage "www-servers/nginx" do
  version "1.9.7" 

  flags ['nginx_modules_http_stub_status']

  # accept keywords by default, but if you want to disable:
  # keywords []

  # Mask =version and unmask !=version
  pin true
end
```

- action: install (default), remove
- unmask (nil/bool):
- pin (bool):
- noreplace (bool, default=true):
- oneshot (bool, default=false):
- flags (array)
- keywords (array,default=[$ARCH])
- package_use_file
- package_mask_file
- package_unmask_file
- package_accept_keywords_file
- emerge_cmd:
- eix_cmd:

### `portage_accept_keywords` resource

```
portage_accept_keywords "www-servers/nginx" do
  keywords ['~amd64']
end
```

- `keywords`: Default to `$ARCH` (`eix --print ARCH`)

### `portage_mask` resource

### `portage_pin` resource

### `portage_package` resource

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/itamae-plugin-resource-portage.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

