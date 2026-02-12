import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/guide_model.dart';

void main() {
  group('Guide Model Tests', () {
    test('BlessingDefinition serialization', () {
      const blessing = BlessingDefinition(
        id: 'blessing-1',
        name: 'Sol Invictus',
        trigger: 'On active',
        effect: 'Blue pulse',
      );

      final json = blessing.toJson();
      final restored = BlessingDefinition.fromJson(json);

      expect(restored.id, blessing.id);
      expect(restored.name, blessing.name);
      expect(restored.trigger, blessing.trigger);
      expect(restored.effect, blessing.effect);
    });

    test('Guide creation and firestore serialization', () {
      final guide = Guide(
        id: 'helioforja',
        name: 'Helioforja',
        title: 'El Primer Pulso',
        affinity: 'Prioridad',
        blessingIds: ['blessing-1'],
        themePrimaryHex: '#FF0000',
        blessings: [
          const BlessingDefinition(
            id: 'bl-1',
            name: 'Poder',
            trigger: 'Start',
            effect: 'Glow',
          ),
        ],
      );

      final firestore = guide.toFirestore();
      final restored = Guide.fromFirestore(firestore);

      expect(restored.id, guide.id);
      expect(restored.name, guide.name);
      expect(restored.blessingIds, contains('blessing-1'));
      expect(restored.themePrimaryHex, '#FF0000');
      expect(restored.blessings.length, 1);
      expect(restored.blessings.first.name, 'Poder');
    });

    test('copyWith creates updated instance', () {
      const original = Guide(
        id: 'aethel',
        name: 'Aethel',
        title: 'Title',
        affinity: 'Affinity',
      );

      final copy = original.copyWith(
        name: 'Updated Aethel',
        title: 'New Title',
      );

      expect(copy.name, 'Updated Aethel');
      expect(copy.title, 'New Title');
      expect(copy.id, original.id);
      expect(copy.affinity, original.affinity);
    });
  });
}
