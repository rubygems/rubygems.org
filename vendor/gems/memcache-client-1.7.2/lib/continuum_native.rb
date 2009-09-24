module Continuum

  class << self

    # Native extension to perform the binary search within the continuum
    # space.  There's a pure ruby version in memcache.rb so this is purely
    # optional for performance and only necessary if you are using multiple
    # memcached servers.
    begin
      require 'inline'
      inline do |builder|
        builder.c <<-EOM
        int binary_search(VALUE ary, unsigned int r) {
            int upper = RARRAY_LEN(ary) - 1;
            int lower = 0;
            int idx = 0;
            ID value = rb_intern("value");

            while (lower <= upper) {
                idx = (lower + upper) / 2;

                VALUE continuumValue = rb_funcall(RARRAY_PTR(ary)[idx], value, 0);
                unsigned int l = NUM2UINT(continuumValue);
                if (l == r) {
                    return idx;
                }
                else if (l > r) {
                    upper = idx - 1;
                }
                else {
                    lower = idx + 1;
                }
            }
            return upper;
        }
        EOM
      end
    rescue Exception => e
    end
  end
end