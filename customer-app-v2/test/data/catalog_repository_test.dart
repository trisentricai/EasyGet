import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easyget/core/network/api_client.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body) => ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _productsJson = '''
{"count":2,"next":null,"previous":null,"results":[
  {"id":1,"name":"Aashirvaad Atta 5kg","slug":"aashirvaad-atta-5kg",
   "brand":"Aashirvaad","mrp":"325.00","base_price":"289.00",
   "discount_percent":11,"is_featured":true,
   "primary_image":"products/atta.jpg","rating_avg":"4.3","rating_count":212},
  {"id":2,"name":"Tata Salt 1kg","slug":"tata-salt-1kg",
   "brand":{"id":7,"name":"Tata","slug":"tata","logo":null},
   "mrp":"28.00","base_price":"28.00","discount_percent":0,
   "is_featured":false,"primary_image":null,"rating_avg":"0.0","rating_count":0}
]}''';

const _detailJson = '''
{"id":1,"name":"Aashirvaad Atta 5kg","slug":"aashirvaad-atta-5kg",
 "brand":"Aashirvaad","mrp":"325.00","base_price":"289.00",
 "discount_percent":11,"is_featured":true,"primary_image":"products/atta.jpg",
 "rating_avg":"4.3","rating_count":212,"description":"Whole wheat flour",
 "offers":[{"code":"SAVE10","name":"Save 10","description":"Get 10% off",
   "discount_type":"PERCENT","discount_value":"10","max_discount":"50"}],
 "variants":[{"id":5,"name":"5 kg","sku":"ATTA-5","price":"289.00",
   "discount_percent":11,"is_active":true}],
 "images":[{"url":"products/atta-1.jpg","is_primary":true,"align_x":"0.5",
   "align_y":"0.5","zoom":"1.0","effect":"ZOOM","transition_ms":250}]}''';

const _categoriesJson = '''
[{"id":1,"name":"Grocery","slug":"grocery","parent":null,
  "image":"cat/grocery.png","has_children":true,"product_count":48},
 {"id":2,"name":"Snacks","slug":"snacks","parent":1,
  "image":null,"has_children":false,"product_count":12}]''';

const _brandsJson = '''
{"results":[{"id":7,"name":"Tata","slug":"tata","logo":"brands/tata.png"}]}''';

const _searchJson = '''
{"results":[{"id":2,"name":"Tata Salt 1kg","slug":"tata-salt-1kg",
  "brand":"Tata","mrp":"28.00","base_price":"28.00","discount_percent":0,
  "is_featured":false,"primary_image":null,"rating_avg":"0.0","rating_count":0}],
 "total":1,"page":1,"page_size":20,"took_ms":7,"query":"salt"}''';

const _pincodeJson = '''
{"valid":true,"pincode":"560001","city":"Bengaluru","state":"Karnataka",
 "eta_days":1,"delivery_fee":"29.00","free_delivery_over":"499.00","source":"DB"}''';

const _storefrontJson = '''
{"store":{"id":1,"name":"EASYGET","slug":"easyget","city":"Bengaluru",
  "description":"Everything, fast"},
 "theme":{"primary_color":"#E4572E","secondary_color":"#F0A202",
  "background_color":"#FBF7F0","font_family":"Poppins","logo":"theme/logo.png",
  "hero_image":"theme/hero.jpg","button_style":"ROUNDED"},
 "sections":[
   {"id":1,"type":"HERO","title":"Fresh in 10","subtitle":"Groceries",
    "image":"sec/hero.jpg","config":{"height":220},
    "items":[{"id":11,"item_type":"PRODUCT","product_slug":"tata-salt-1kg",
      "product_price":"28.00","caption":"Salt","image":null,"link":null,
      "config":{}}]},
   {"id":2,"type":"CATEGORY_GRID","title":"Shop by category","config":{},
    "items":[]}],
 "ticker":{"items":["Free delivery over 499"],"speed":40,"color":"#FFFFFF",
  "bg":"#E4572E","symbol":"\u20b9","font_size":13,"radius":8}}''';

void main() {
  late List<RequestOptions> seen;
  late HttpCatalogRepository repo;

  HttpCatalogRepository build(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
    dio.httpClientAdapter = _FakeAdapter((options) {
      seen.add(options);
      return handler(options);
    });
    return HttpCatalogRepository(ApiClient(dio));
  }

  group('products', () {
    test('maps the filter query and decodes CatalogProduct rows', () async {
      repo = build((_) async => _json(_productsJson));

      final page = await repo.products(
        category: 'grocery',
        brand: 'tata',
        minPrice: 10,
        maxPrice: 500,
        minDiscount: 5,
        isFeatured: true,
        sort: 'price_asc',
        page: 2,
      );

      expect(seen.single.path, '/products/');
      expect(seen.single.queryParameters, {
        'category': 'grocery',
        'brand': 'tata',
        'min_price': 10,
        'max_price': 500,
        'min_discount': 5,
        'is_featured': true,
        'sort': 'price_asc',
        'page': 2,
      });

      expect(page.results, hasLength(2));
      expect(page.total, 2);

      final first = page.results.first;
      expect(first.id, 1);
      expect(first.name, 'Aashirvaad Atta 5kg');
      expect(first.slug, 'aashirvaad-atta-5kg');
      expect(first.brand, 'Aashirvaad');
      expect(first.mrp, 325.0);
      expect(first.basePrice, 289.0);
      expect(first.discountPercent, 11);
      expect(first.isFeatured, isTrue);
      expect(first.primaryImage, 'products/atta.jpg');
      expect(first.ratingAvg, 4.3);
      expect(first.ratingCount, 212);

      // Tolerant of a nested brand object and null numerics.
      final second = page.results[1];
      expect(second.brand, 'Tata');
      expect(second.primaryImage, isNull);
      expect(second.ratingCount, 0);
    });

    test('decodes product detail incl. variants, images, offers', () async {
      repo = build((_) async => _json(_detailJson));

      final d = await repo.product('aashirvaad-atta-5kg');

      expect(seen.single.path, '/products/aashirvaad-atta-5kg/');
      expect(d.description, 'Whole wheat flour');
      expect(d.variants.single.id, 5);
      expect(d.variants.single.name, '5 kg');
      expect(d.variants.single.sku, 'ATTA-5');
      expect(d.variants.single.price, 289.0);
      expect(d.variants.single.isActive, isTrue);
      expect(d.images.single.url, 'products/atta-1.jpg');
      expect(d.images.single.isPrimary, isTrue);
      expect(d.images.single.zoom, 1.0);
      expect(d.images.single.effect, 'ZOOM');
      expect(d.offers.single.code, 'SAVE10');
      expect(d.offers.single.discountType, 'PERCENT');
      expect(d.offers.single.discountValue, 10.0);
    });

    test('decodes the live image shape (image key + percent align)',
        () async {
      const live = '''
{"id":1,"name":"X","slug":"x","brand":"B","mrp":"20.00","base_price":"20.00",
"images":[{"id":25,"image":"products/p.webp","caption":"","is_primary":true,
"sort_order":1,"align_x":50,"align_y":50,"zoom":1.0,"effect":"none"}]}''';
      repo = build((_) async => _json(live));

      final d = await repo.product('x');

      expect(d.images.single.url, 'products/p.webp');
      expect(d.images.single.isPrimary, isTrue);
      expect(d.images.single.alignX, 0.5);
      expect(d.images.single.alignY, 0.5);
    });
  });

  group('categories + brands', () {
    test('fetchCategories decodes a flat list', () async {
      repo = build((_) async => _json(_categoriesJson));

      final cats = await repo.categories();

      expect(seen.single.path, '/categories/');
      expect(cats, hasLength(2));
      expect(cats.first.id, 1);
      expect(cats.first.name, 'Grocery');
      expect(cats.first.slug, 'grocery');
      expect(cats.first.parent, isNull);
      expect(cats.first.hasChildren, isTrue);
      expect(cats.first.productCount, 48);
      expect(cats[1].parent, 1);
    });

    test('fetchBrands decodes {name,slug,logo} from a paged envelope',
        () async {
      repo = build((_) async => _json(_brandsJson));

      final brands = await repo.brands();

      expect(seen.single.path, '/products/brands/');
      expect(brands.single.id, 7);
      expect(brands.single.name, 'Tata');
      expect(brands.single.slug, 'tata');
      expect(brands.single.logo, 'brands/tata.png');
    });
  });

  group('search', () {
    test('POSTs {q,sort,page} and maps result rows to CatalogProduct',
        () async {
      repo = build((_) async => _json(_searchJson));

      final page = await repo.search('salt', sort: 'relevance', page: 1);

      expect(seen.single.path, '/search/');
      expect(seen.single.data, {'q': 'salt', 'sort': 'relevance', 'page': 1});
      expect(page.total, 1);
      expect(page.results.single.name, 'Tata Salt 1kg');
      expect(page.results.single.basePrice, 28.0);
    });
  });

  group('pincode', () {
    test('decodes string fees into numbers', () async {
      repo = build((_) async => _json(_pincodeJson));

      final info = await repo.pincode('560001');

      expect(seen.single.path, '/pincode/560001/');
      expect(info.valid, isTrue);
      expect(info.city, 'Bengaluru');
      expect(info.state, 'Karnataka');
      expect(info.etaDays, 1);
      expect(info.deliveryFee, 29.0);
      expect(info.freeDeliveryOver, 499.0);
    });
  });

  group('storefront', () {
    test('platform storefront decodes store, theme, sections, ticker',
        () async {
      repo = build((_) async => _json(_storefrontJson));

      final render = await repo.platformStorefront();

      expect(seen.single.path, '/storefront/platform/');
      expect(render.store.name, 'EASYGET');
      expect(render.store.slug, 'easyget');
      expect(render.theme.primaryColor, '#E4572E');
      expect(render.theme.fontFamily, 'Poppins');
      expect(render.sections, hasLength(2));
      expect(render.sections.first.type, 'HERO');
      expect(render.sections.first.title, 'Fresh in 10');
      expect(render.sections.first.items.single.productSlug, 'tata-salt-1kg');
      expect(render.sections.first.items.single.productPrice, 28.0);
      expect(render.ticker!.items.single, 'Free delivery over 499');
      expect(render.ticker!.bg, '#E4572E');
    });

    test('storefront(slug) hits the per-store path', () async {
      repo = build((_) async => _json(_storefrontJson));

      await repo.storefront('my-store');

      expect(seen.single.path, '/storefront/my-store/');
    });
  });
}