class Grammar::Expression::Table {
    has %.hash;

    method at_key(|k) { %!hash.at_key(|k) }

    method new-prec($name, :$loosest!, *%config) {
        new-prec($name, :prec($.loosest - 1), |%config)
    }
    method new-prec($name, :$tightest!, *%config) {
        new-prec($name, :prec($.tightest + 1), |%config)
    }
    method new-prec($name, :$tightest!, :$loosest!, *%config) {
        die "Precedence '$name' can't be both tightest and loosest";
    }
    method new-prec($name, *%config) {
        %!hash{$name} =
            :prec(%config<prec>:delete // $.loosest - 1),
            :assoc(%config<assoc>:delete // 'unary'),
            :uassoc(%config<uassoc>:delete // 'non'),
            :dba(%config<dba>:delete // $name),
            |%config;
    }

#    method add(*%h) {
#        for %h -> (:key($name), :value(%p)) {
#            %!hash{$name} =
#                :prec(%p<prec>:delete // self.loosest - 1),
#                :assoc(%p<assoc>:delete // 'unary'),
#                :uassoc(%p<uassoc>:delete),
#                :dba(%p<dba>:delete // $name),
#                |%p;
#        }
#    }

    method loosest  { (%!hash{*}»<prec> // 0).min }
    method tightest { (%!hash{*}»<prec> // 0).max }
}
