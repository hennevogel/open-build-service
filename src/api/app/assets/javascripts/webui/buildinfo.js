function normalizeData() {
  var rawData = $('#build-info-raw-data').text();

  // encoding and shaping newline properly
  var normalizedData = rawData.replace(/\\n/g, '\n');
  normalizedData = normalizedData.replace(/\",/g, '",\n');

  const errorMessage = normalizedData.match(/\"error\"\=\>\"(.*)\"/)[1];
  $('#build-info-error-message').text(errorMessage);

  const directDependencies = normalizedData.match(/expand args: (.*)/)[1];
  $('#build-info-direct-dependencies').text(directDependencies);

  $('#build-info-chained-dependencies').html(() => {
    let chainedDependencies = "";
    normalizedData.match(/added (.*) because of (.*)/g).forEach(element => {
      chainedDependencies += '<div>' + element + '</div>';
    });
    return chainedDependencies;
  });
}
