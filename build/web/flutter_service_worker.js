'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "54635ec8419fea2f718b119654b5e56d",
"version.json": "83406697b526678a8ac53015450ecced",
"index.html": "993bbad34fe69cf37e45bc365614bf41",
"/": "993bbad34fe69cf37e45bc365614bf41",
"main.dart.js": "f1150332ea4a32249a75dcd1b7ef5280",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "f380822570f46effc41e49557733a1db",
"icons/Icon-192.png": "102f551c36726825493331d1fdd88194",
"icons/Icon-maskable-192.png": "102f551c36726825493331d1fdd88194",
"icons/Icon-maskable-512.png": "96283b548c56d6f204a2e460dbeaa3ed",
"icons/Icon-512.png": "96283b548c56d6f204a2e460dbeaa3ed",
"manifest.json": "a095e2b940045880cda7ec43082dcc13",
"assets/images/Icon-App_3_Darkmode.png": "c29ab47e80e6c70bf0796a83bf49d395",
"assets/images/fairy.png": "75d958c7c0edeaaa584c937793188930",
"assets/images/muscles/Front_forearms.png": "581e0c6a87a859557396eb72abc52810",
"assets/images/muscles/sideview.png": "c60aee4474bd39b49bb781e8e8ed9192",
"assets/images/muscles/Back_Front_delts.png": "6c5135e9d5355b6e58f72ea2b542a490",
"assets/images/muscles/Back_lats.png": "677f00879418ab5abd13c3a59b1a5bed",
"assets/images/muscles/Back_trapz.png": "cea08cb0fb9636cf364e5306b1e32a1b",
"assets/images/muscles/Front_biceps.png": "ca4958dff4836ca3627e05927078ad5a",
"assets/images/muscles/Back_triceps.png": "2488ecc5946f586aa31258db987d528b",
"assets/images/muscles/Front_trapz.png": "5f0fe430e14ad5b094b3190e3a69e56d",
"assets/images/muscles/Back_calves.png": "9f9b587b8dc7c80a501ab5bb1aff23f8",
"assets/images/muscles/Front_calves.png": "ed58904716c23cae236320bcd7c117b1",
"assets/images/muscles/Back_Back_delts.png": "bfb6f0c30f7c5c2de5fdfa5ef3dc2cc0",
"assets/images/muscles/Front_sideabs.png": "9392103706943ad6edf2511f7a1d6ddb",
"assets/images/muscles/Back_bg.png": "c3030aa6dc07fb37ba58bef32b74a32b",
"assets/images/muscles/Front_quads.png": "1db6a0982defee6e7814c75e6c7e5b9c",
"assets/images/muscles/Back_bg.psd": "0d671acfa16624ee82e44487b6a9205f",
"assets/images/muscles/Back_hamstrings.png": "578562eef5e0f0d87b55569dd842a96d",
"assets/images/muscles/Front_Front_delts.png": "7f6f96e9c2994602421f36878d3a3bf8",
"assets/images/muscles/Front_bg.png": "6ef5850c6d195d82a4154c39a4fe391f",
"assets/images/muscles/Back_bg_old.png": "49dac22b830b4fd066a659ef559c5fbb",
"assets/images/muscles/Back_forearms.png": "998b38111a6864d077ff916c6557edd9",
"assets/images/muscles/Front_pecs.png": "878ee54a1800fc52bab8052960c3c5d6",
"assets/images/muscles/Back_Side_delts.png": "b23cfbe9c524731bef277bc42f2aee3b",
"assets/images/muscles/Back_Back_delts2.png": "d0e5e4c465ee12ceaa9073151e9d171d",
"assets/images/muscles/Back_glutes.png": "f8e10d11e59e3271ad416e84e522a399",
"assets/images/muscles/Front_abs.png": "61deab6aff21aa0a46adb8c0706195e2",
"assets/images/menu2.jpeg": "24c40adfd15a527f7d3913e3366b6e8a",
"assets/images/menu2.png": "3f05f25cb05d50f5418ac79712aa727d",
"assets/images/menu1.jpg": "816a9cdda2f92e1f01b20043133f4991",
"assets/images/logo.jpeg": "2d2338839088be1321b879060a2beace",
"assets/images/MuscleTemp.jpeg": "2cd024e2e3ac4e925e06a4d2fb47d970",
"assets/images/Icon-App_3.png": "ddfcb3e2f4cc742f699749c3c37a383b",
"assets/AssetManifest.json": "33ba945451b7cab0bf1f238676db8463",
"assets/NOTICES": "19388fbbd57b82b48dee6cf1cfe170da",
"assets/FontManifest.json": "3ddd9b2ab1c2ae162d46e3cc7b78ba88",
"assets/AssetManifest.bin.json": "47af9708607bd4e36d89210622b29ac9",
"assets/csv/set.csv": "068ae5703487c52b87c3d694a5e3ae9f",
"assets/csv/ex.csv": "c5c7badaf52685f01782a2801c8d72f8",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "8c1ff8d038853f2750ce4e01a4bcfd9e",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "f3307f62ddff94d2cd8b103daf8d1b0f",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "17ee8e30dde24e349e70ffcdc0073fb0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "cc505bf7207be994f56c6553461bf0e4",
"assets/fonts/MaterialIcons-Regular.otf": "50cefce166c43cfa2f7efb416a317ad5",
"assets/assets/appainter_theme.json": "0ccd86445af30fc1efd08aca50e4cbbe",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
