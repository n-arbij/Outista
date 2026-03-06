import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/core/errors/data_exception.dart';
import 'package:outista/core/services/image_storage_service.dart';
import 'package:outista/data/datasources/local/local_clothing_datasource.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/features/add_item/domain/usecases/add_item_usecase.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class _MockClothingDatasource extends Mock
    implements LocalClothingDatasource {}

class _MockImageStorageService extends Mock implements ImageStorageService {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const _rawPath = '/tmp/raw.jpg';
const _savedPath = '/docs/wardrobe_images/uuid.jpg';

const _input = AddItemInput(
  imagePath: _rawPath,
  category: ClothingCategory.top,
  season: ClothingSeason.allWeather,
  occasion: ClothingOccasion.casual,
  emotionalTag: EmotionalTag.favorite,
);

void main() {
  late _MockClothingDatasource mockRepo;
  late _MockImageStorageService mockStorage;
  late AddItemUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ClothingItemModel(
        id: 'fallback',
        imagePath: '',
        category: ClothingCategory.top,
        season: ClothingSeason.allWeather,
        occasion: ClothingOccasion.casual,
        createdAt: DateTime(2024),
      ),
    );
  });

  setUp(() {
    mockRepo = _MockClothingDatasource();
    mockStorage = _MockImageStorageService();
    useCase = AddItemUseCase(mockRepo, mockStorage);
  });

  group('AddItemUseCase.call()', () {
    test('saves image and creates item with correct field values', () async {
      when(() => mockStorage.saveImage(_rawPath))
          .thenAnswer((_) async => _savedPath);
      when(() => mockRepo.addItem(any())).thenAnswer((_) async {});

      final result = await useCase.call(_input);

      verify(() => mockStorage.saveImage(_rawPath)).called(1);
      verify(() => mockRepo.addItem(any())).called(1);

      expect(result.imagePath, equals(_savedPath));
      expect(result.category, ClothingCategory.top);
      expect(result.season, ClothingSeason.allWeather);
      expect(result.occasion, ClothingOccasion.casual);
      expect(result.emotionalTag, EmotionalTag.favorite);
    });

    test('returned model has usageCount = 0 and createdAt set', () async {
      when(() => mockStorage.saveImage(_rawPath))
          .thenAnswer((_) async => _savedPath);
      when(() => mockRepo.addItem(any())).thenAnswer((_) async {});

      final before = DateTime.now();
      final result = await useCase.call(_input);
      final after = DateTime.now();

      expect(result.usageCount, equals(0));
      expect(
        result.createdAt.millisecondsSinceEpoch,
        inInclusiveRange(
          before.millisecondsSinceEpoch,
          after.millisecondsSinceEpoch,
        ),
      );
    });

    test('returned model imagePath matches saved path from service', () async {
      when(() => mockStorage.saveImage(_rawPath))
          .thenAnswer((_) async => _savedPath);
      when(() => mockRepo.addItem(any())).thenAnswer((_) async {});

      final result = await useCase.call(_input);

      expect(result.imagePath, _savedPath);
    });

    test('throws DataException when imageStorageService fails', () async {
      when(() => mockStorage.saveImage(any()))
          .thenThrow(Exception('disk full'));

      expect(
        () => useCase.call(_input),
        throwsA(isA<DataException>()),
      );
    });

    test('throws DataException when repository.addItem fails', () async {
      when(() => mockStorage.saveImage(any()))
          .thenAnswer((_) async => _savedPath);
      when(() => mockRepo.addItem(any()))
          .thenThrow(DataException('db error'));

      expect(
        () => useCase.call(_input),
        throwsA(isA<DataException>()),
      );
    });
  });
}
