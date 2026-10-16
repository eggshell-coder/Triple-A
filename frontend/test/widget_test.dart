// test/widget_test.dart
//
// Replaces the stock Flutter counter template that shipped with
// `flutter create` — it referenced a `MyApp` class this project never had,
// so `flutter analyze` / `flutter test` failed out of the box.
//
// These cover the logic that's easy to break and actually matters:
// cart maths, the stock guard, and the responsive image sizing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:triple_a/models/models.dart';
import 'package:triple_a/providers/cart_provider.dart';
import 'package:triple_a/config/responsive.dart';

Product _product({
  String id = 'p1',
  String name = 'Cotton T-Shirt',
  double price = 600,
  int stock = 10,
}) =>
    Product(id: id, name: name, price: price, stock: stock);

void main() {
  group('CartNotifier', () {
    test('adds a new product as its own line', () {
      final cart = CartNotifier();
      cart.addItem(_product());
      expect(cart.state.length, 1);
      expect(cart.itemCount, 1);
    });

    test('merges a repeat product and sums quantity', () {
      final cart = CartNotifier();
      cart.addItem(_product());
      cart.addItem(_product(), quantity: 2);
      expect(cart.state.length, 1, reason: 'should merge into one line');
      expect(cart.itemCount, 3);
    });

    test('total is price x quantity across lines', () {
      final cart = CartNotifier();
      cart.addItem(_product(id: 'a', price: 600));
      cart.addItem(_product(id: 'b', price: 450), quantity: 2);
      expect(cart.total, 1500);
      expect(cart.itemCount, 3);
    });

    test('stock guard rejects a merge that would exceed stock', () {
      final cart = CartNotifier();
      cart.addItem(_product(stock: 3));
      cart.addItem(_product(stock: 3), quantity: 5);
      // The notifier keeps the existing quantity rather than overselling.
      expect(cart.itemCount, lessThanOrEqualTo(3));
      expect(cart.state.single.quantity, 1);
    });

    test('stock guard allows a merge that stays within stock', () {
      final cart = CartNotifier();
      cart.addItem(_product(stock: 5));
      cart.addItem(_product(stock: 5), quantity: 2);
      expect(cart.itemCount, 3);
    });

    test('updateQuantity to zero removes the line', () {
      final cart = CartNotifier();
      cart.addItem(_product());
      cart.updateQuantity('p1', 0);
      expect(cart.state, isEmpty);
    });

    test('updateQuantity replaces rather than adds', () {
      final cart = CartNotifier();
      cart.addItem(_product(), quantity: 3);
      cart.updateQuantity('p1', 2);
      expect(cart.itemCount, 2);
    });

    test('removeItem drops only the matching line', () {
      final cart = CartNotifier();
      cart.addItem(_product(id: 'a'));
      cart.addItem(_product(id: 'b'));
      cart.removeItem('a');
      expect(cart.state.single.product.id, 'b');
    });

    test('clear empties the cart', () {
      final cart = CartNotifier();
      cart.addItem(_product());
      cart.clear();
      expect(cart.state, isEmpty);
      expect(cart.total, 0);
    });
  });

  group('Product model', () {
    test('fromJson maps the API shape', () {
      final p = Product.fromJson({
        'id': 'abc',
        'name': 'Black Tee',
        'price': 800,
        'stock': 4,
        'image_url': 'https://example.com/a.png',
        'categories': {'name': 'Graphic Tees'},
      });
      expect(p.id, 'abc');
      expect(p.price, 800);
      expect(p.imageUrl, 'https://example.com/a.png');
      expect(p.categoryName, 'Graphic Tees');
      expect(p.inStock, isTrue);
    });

    test('fromJson survives missing fields', () {
      final p = Product.fromJson({});
      expect(p.id, '');
      expect(p.price, 0);
      expect(p.inStock, isFalse);
    });

    test('inStock is false at zero stock', () {
      expect(_product(stock: 0).inStock, isFalse);
    });

    test('categoryName falls back when no category', () {
      expect(_product().categoryName, 'Uncategorized');
    });
  });

  // These are the values that fixed the "image too big on mobile" bug,
  // so pin them against accidental regressions.
  //
  // Each test sets the real view size rather than wrapping in a MediaQuery,
  // and asserts AFTER pumping. Asserting inside a Builder callback couples
  // the check to build order and produces flaky failures when several
  // widths are pumped in one test.
  group('Responsive sizing', () {
    test('image ratio is the 3:4 retail standard', () {
      expect(Responsive.productImageRatio, 0.75);
    });

    testWidgets('phone / tablet / desktop classification', (tester) async {
      // Exactly one bucket is active at any width.
      expect(await _classify(tester, 390), 'phone');
      expect(await _classify(tester, 768), 'tablet');
      expect(await _classify(tester, 1440), 'desktop');
    });

    testWidgets('grid columns grow with width', (tester) async {
      expect(await _columns(tester, 390), 2);
      expect(await _columns(tester, 768), 4);
      expect(await _columns(tester, 1440), 5);
    });

    testWidgets('detail image height stays inside the phone clamp',
        (tester) async {
      final h = await _detailHeight(tester, 390);
      expect(h, inInclusiveRange(240, 420));
      expect(h, lessThan(844 * 0.5),
          reason: 'hero must not swallow the whole phone screen');
    });

    testWidgets('detail title scales down on phones', (tester) async {
      final phone = await _detailTitle(tester, 390);
      final desktop = await _detailTitle(tester, 1440);
      expect(phone, lessThan(desktop));
    });

    testWidgets('page padding is narrower on phones', (tester) async {
      final phone = await _padding(tester, 390);
      final desktop = await _padding(tester, 1440);
      expect(phone, lessThan(desktop));
    });
  });

  group('Cart badge count (navbar)', () {
    testWidgets('sums quantity across cart lines', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(cartProvider).fold<int>(
                0,
                (s, item) => s + item.quantity,
              );
              return Text('$count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      final container = ProviderScope.containerOf(tester.element(find.text('0')));
      container.read(cartProvider.notifier).addItem(_product(), quantity: 3);
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });
  });
}

/// Sets the real view size, pumps, and hands the BuildContext to [read].
///
/// Reading after the pump (rather than inside a Builder callback) keeps the
/// assertions out of build order, which is what made the earlier version
/// of this file flaky.
Future<T> _measure<T>(WidgetTester tester, double width, T Function(BuildContext) read) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  late T result;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: (context) {
        result = read(context);
        return const SizedBox.shrink();
      }),
    ),
  );
  return result;
}

Future<String> _classify(WidgetTester tester, double width) =>
    _measure(tester, width, (c) {
      if (Responsive.isPhone(c)) return 'phone';
      if (Responsive.isTablet(c)) return 'tablet';
      if (Responsive.isDesktop(c)) return 'desktop';
      return 'unknown';
    });

Future<int> _columns(WidgetTester tester, double width) =>
    _measure(tester, width, (c) => Responsive.productColumns(c));

Future<double> _detailHeight(WidgetTester tester, double width) =>
    _measure(tester, width, (c) => Responsive.detailImageHeight(c));

Future<double> _detailTitle(WidgetTester tester, double width) =>
    _measure(tester, width, (c) => Responsive.detailTitleSize(c));

Future<double> _padding(WidgetTester tester, double width) =>
    _measure(tester, width, (c) => Responsive.pagePadding(c).left);