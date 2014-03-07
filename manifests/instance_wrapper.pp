#class swagger::instance_wrapper
class swagger::instance_wrapper($instance) {
  $real_instance = hiera_hash(swagger::instance_wrapper::instance)
  create_resources(swagger::instance, $real_instance)
}
