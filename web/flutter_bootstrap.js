{{flutter_js}}
{{flutter_build_config}}

// Keep the demo independent of the Google renderer CDN. Flutter serves these
// SDK assets locally in debug runs and includes them in release web builds.
_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' },
}).catch((error) => {
  console.error('FixFlow could not start', error);
  const loading = document.getElementById('loading');
  if (loading) {
    loading.textContent = 'FixFlow could not start. Please refresh the page. If it continues, check the browser console for the startup error.';
    loading.setAttribute('role', 'alert');
  }
});
