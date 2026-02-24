import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fy_project/services/goal_service.dart';
import 'package:fy_project/models/smart_goal.dart';

void main() {
  group('GoalService Tests', () {
    late GoalService goalService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      goalService = GoalService(firestore: fakeFirestore);
    });

    group('Goal CRUD Operations', () {
      test('addGoal adds goal to Firestore', () async {
        final goal = SmartGoal(
          id: '',
          userId: 'user-123',
          title: 'Exercise 3 times per week',
          description: 'Go to the gym or do home workout',
          targetValue: 3.0,
          currentValue: 0.0,
          unit: 'sessions',
          deadline: DateTime.now().add(const Duration(days: 30)),
          colorValue: 0xFF4CAF50,
          isCompleted: false,
        );

        await goalService.addGoal(goal);

        // Verify the goal was written to the fake Firestore
        final snapshot = await fakeFirestore
            .collection('smart_goals')
            .where('userId', isEqualTo: 'user-123')
            .get();
        expect(snapshot.docs, isNotEmpty);
        expect(snapshot.docs.first.data()['title'], equals(goal.title));
      });

      test('updateGoal modifies existing goal', () async {
        final goal = SmartGoal(
          id: 'goal-2',
          userId: 'user-123',
          title: 'Read 1 book per month',
          description: 'Read before bed',
          targetValue: 1.0,
          currentValue: 0.0,
          unit: 'books',
          deadline: DateTime.now().add(const Duration(days: 30)),
          colorValue: 0xFF2196F3,
          isCompleted: false,
        );

        await fakeFirestore
            .collection('smart_goals')
            .doc(goal.id)
            .set(goal.toMap());

        final updatedGoal = goal.copyWith(isCompleted: true);
        await goalService.updateGoal(updatedGoal);

        final doc = await fakeFirestore
            .collection('smart_goals')
            .doc(goal.id)
            .get();
        expect(doc.data()?['isCompleted'], isTrue);
      });

      test('updateProgress updates current value', () async {
        const goalId = 'goal-3';
        const newValue = 2.0;

        await fakeFirestore.collection('smart_goals').doc(goalId).set({
          'currentValue': 0.0,
          'userId': 'user-123',
        });

        await goalService.updateProgress(goalId, newValue);

        final doc = await fakeFirestore
            .collection('smart_goals')
            .doc(goalId)
            .get();
        expect(doc.data()?['currentValue'], equals(newValue));
      });

      test('updateCompletionStatus marks goal as completed', () async {
        const goalId = 'goal-4';

        await fakeFirestore.collection('smart_goals').doc(goalId).set({
          'isCompleted': false,
          'userId': 'user-123',
        });

        await goalService.updateCompletionStatus(goalId, true);

        final doc = await fakeFirestore
            .collection('smart_goals')
            .doc(goalId)
            .get();
        expect(doc.data()?['isCompleted'], isTrue);
      });

      test('deleteGoal removes goal from Firestore', () async {
        const goalId = 'goal-to-delete';

        await fakeFirestore.collection('smart_goals').doc(goalId).set({
          'title': 'To be deleted',
          'userId': 'user-123',
        });

        await goalService.deleteGoal(goalId);

        final doc = await fakeFirestore
            .collection('smart_goals')
            .doc(goalId)
            .get();
        expect(doc.exists, isFalse);
      });
    });

    group('Goal Streams', () {
      test('getGoalsStream returns stream of goals for user', () async {
        const userId = 'user-stream-123';
        final goal = SmartGoal(
          id: 'stream-goal',
          userId: userId,
          title: 'Stream Goal',
          description: 'Testing stream',
          targetValue: 5.0,
          currentValue: 1.0,
          unit: 'reps',
          deadline: DateTime.now().add(const Duration(days: 7)),
          colorValue: 0xFF9C27B0,
          isCompleted: false,
        );

        await fakeFirestore
            .collection('smart_goals')
            .doc(goal.id)
            .set({...goal.toMap(), 'deadline': goal.deadline.toIso8601String()});

        final stream = goalService.getGoalsStream(userId);
        expect(stream, isA<Stream<List<SmartGoal>>>());
      });

      test('getGoalsStream emits empty list for user with no goals', () async {
        final stream = goalService.getGoalsStream('empty-user');
        final goals = await stream.first;
        expect(goals, isEmpty);
      });
    });
  });
}
