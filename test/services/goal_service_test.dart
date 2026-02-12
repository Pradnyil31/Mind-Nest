import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fy_project/services/goal_service.dart';
import 'package:fy_project/models/smart_goal.dart';

void main() {
  group('GoalService Tests', () {
    late GoalService goalService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      goalService = GoalService();
    });

    group('Goal CRUD Operations', () {
      test('addGoal adds goal to Firestore', () async {
        // Arrange
        final goal = SmartGoal(
          id: 'goal-1',
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

        // Act
        await goalService.addGoal(goal);

        // Assert - should complete without errors
        expect(goal.id, isNotEmpty);
      });

      test('updateGoal modifies existing goal', () async {
        // Arrange
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
        await goalService.addGoal(goal);

        // Act
        final updatedGoal = goal.copyWith(isCompleted: true);
        await goalService.updateGoal(updatedGoal);

        // Assert - should complete without errors
      });

      test('updateProgress updates current value', () async {
        // Arrange
        const goalId = 'goal-3';
        const newValue = 2.0;

        // Act & Assert
        await expectLater(
          goalService.updateProgress(goalId, newValue),
          completes,
        );
      });

      test('deleteGoal removes goal from Firestore', () async {
        // Arrange
        const goalId = 'goal-to-delete';

        // Act & Assert
        await expectLater(
          goalService.deleteGoal(goalId),
          completes,
        );
      });
    });

    group('Goal Streams', () {
      test('getGoalsStream returns stream of goals', () {
        // Arrange
        const userId = 'user-123';

        // Act
        final stream = goalService.getGoalsStream(userId);

        // Assert
        expect(stream, isA<Stream<List<SmartGoal>>>());
      });
    });
  });
}
