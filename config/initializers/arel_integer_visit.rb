# Handle Integer/Bignum visitors for Arel on Ruby 2.4+ where Fixnum/Bignum were unified.
module Arel
  module Visitors
    [Arel::Visitors::Visitor, Arel::Visitors::ToSql, Arel::Visitors::PostgreSQL, Arel::Visitors::DepthFirst].each do |klass|
      klass.class_eval do
        define_method(:visit_Fixnum) { |o, *_args| o } unless method_defined?(:visit_Fixnum)
        define_method(:visit_Integer) { |o, *args| respond_to?(:visit_Fixnum, true) ? visit_Fixnum(o, *args) : o } unless method_defined?(:visit_Integer)
        define_method(:visit_Bignum) { |o, *args| respond_to?(:visit_Integer, true) ? visit_Integer(o, *args) : o } unless method_defined?(:visit_Bignum)
      end
    end
  end
end
