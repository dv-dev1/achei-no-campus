window.configurarFirebaseAuthLocal = async (options, host) => {
  const version = '12.19.0';
  const core = await import(`https://www.gstatic.com/firebasejs/${version}/firebase-app.js`);
  const auth = await import(`https://www.gstatic.com/firebasejs/${version}/firebase-auth.js`);
  const app = core.initializeApp(options);
  const delegate = auth.initializeAuth(app, {
    errorMap: auth.debugErrorMap,
    persistence: [auth.indexedDBLocalPersistence, auth.browserLocalPersistence, auth.browserSessionPersistence],
    popupRedirectResolver: auth.browserPopupRedirectResolver,
  });
  // FlutterFire aguarda a sessão persistida antes de useAuthEmulator, tarde demais na recarga.
  auth.connectAuthEmulator(delegate, `http://${host}:9099`);
};
