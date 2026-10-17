import 'package:fl_clash/common/exception.dart';
import 'package:fl_clash/common/override_merge.dart';
import 'package:test/test.dart';

void main() {
  group('applyOverrideYaml', () {
    test('overwrites a scalar', () {
      final config = {'mixed-port': 7890};
      final next = applyOverrideYaml(config, 'mixed-port: 7891');
      expect(next['mixed-port'], 7891);
    });

    test('deep merges nested maps and keeps untouched siblings', () {
      final config = {
        'dns': {
          'enable': true,
          'nameserver': ['8.8.8.8'],
        },
        'mode': 'rule',
      };
      final next = applyOverrideYaml(config, '''
dns:
  fake-ip: true
''');
      expect(next['dns'], {
        'enable': true,
        'nameserver': ['8.8.8.8'],
        'fake-ip': true,
      });
      expect(next['mode'], 'rule');
    });

    test('replaces an array by default', () {
      final config = {
        'rules': ['DOMAIN,a.com,DIRECT', 'MATCH,DIRECT'],
      };
      final next = applyOverrideYaml(config, '''
rules:
  - DOMAIN,b.com,DIRECT
''');
      expect(next['rules'], ['DOMAIN,b.com,DIRECT']);
    });

    test('prepends with a leading plus', () {
      final config = {
        'rules': ['DOMAIN,a.com,DIRECT', 'MATCH,DIRECT'],
      };
      final next = applyOverrideYaml(config, '''
+rules:
  - DOMAIN,b.com,DIRECT
  - DOMAIN,c.com,DIRECT
''');
      expect(next['rules'], [
        'DOMAIN,b.com,DIRECT',
        'DOMAIN,c.com,DIRECT',
        'DOMAIN,a.com,DIRECT',
        'MATCH,DIRECT',
      ]);
    });

    test('appends with a trailing plus', () {
      final config = {
        'rules': ['DOMAIN,a.com,DIRECT', 'MATCH,DIRECT'],
      };
      final next = applyOverrideYaml(config, '''
rules+:
  - DOMAIN,b.com,DIRECT
''');
      expect(next['rules'], [
        'DOMAIN,a.com,DIRECT',
        'MATCH,DIRECT',
        'DOMAIN,b.com,DIRECT',
      ]);
    });

    test('creates the list when the target is missing', () {
      final next = applyOverrideYaml(const {}, '''
+rules:
  - MATCH,DIRECT
''');
      expect(next['rules'], ['MATCH,DIRECT']);
    });

    test('replaces a non-list target with the list', () {
      final next = applyOverrideYaml(
        {'rules': 'DOMAIN,a.com,DIRECT'},
        '''
rules+:
  - MATCH,DIRECT
''',
      );
      expect(next['rules'], ['MATCH,DIRECT']);
    });

    test('force replaces a section with a bang', () {
      final config = {
        'dns': {
          'enable': true,
          'nameserver': ['8.8.8.8'],
        },
      };
      final next = applyOverrideYaml(config, '''
dns!:
  enable: false
''');
      expect(next['dns'], {'enable': false});
    });

    test('unwraps an escaped plain key', () {
      final next = applyOverrideYaml(const {}, '''
<+.google.cn>: 1.1.1.1
''');
      expect(next['+.google.cn'], '1.1.1.1');
    });

    test('unwraps an escaped key under the prepend and append operators', () {
      final prepend = applyOverrideYaml(
        {
          '+.google.cn': ['a'],
        },
        '''
+<+.google.cn>:
  - b
''',
      );
      expect(prepend['+.google.cn'], ['b', 'a']);
      final append = applyOverrideYaml(
        {
          '+.google.cn': ['a'],
        },
        '''
<+.google.cn>+:
  - b
''',
      );
      expect(append['+.google.cn'], ['a', 'b']);
    });

    test('leaves a lone plus as a literal key', () {
      final next = applyOverrideYaml(const {}, '+: 1');
      expect(next['+'], 1);
    });

    test('applies operators at nested depth', () {
      final config = {
        'dns': {
          'nameserver': ['8.8.8.8'],
        },
      };
      final next = applyOverrideYaml(config, '''
dns:
  nameserver+:
    - 1.1.1.1
''');
      expect(next['dns']['nameserver'], ['8.8.8.8', '1.1.1.1']);
    });

    test('applies the merge key of an override document', () {
      final config = {'a': 1};
      final next = applyOverrideYaml(config, '''
<<: {b: 2}
''');
      expect(next, {'a': 1, 'b': 2});
    });

    test('keeps an empty document a no-op', () {
      final config = {'a': 1};
      expect(applyOverrideYaml(config, ''), same(config));
      expect(applyOverrideYaml(config, '# only a comment'), same(config));
    });

    test('rejects a document that is not a mapping', () {
      expect(
        () => applyOverrideYaml(const {}, '- a\n- b'),
        throwsA(isA<MessageException>()),
      );
    });

    test('does not mutate the input config', () {
      final config = <String, dynamic>{
        'dns': <String, dynamic>{
          'nameserver': <Object?>['8.8.8.8'],
        },
      };
      applyOverrideYaml(config, '''
dns:
  fake-ip: true
  nameserver+:
    - 1.1.1.1
''');
      expect(config['dns'], {
        'nameserver': ['8.8.8.8'],
      });
    });
  });
}
