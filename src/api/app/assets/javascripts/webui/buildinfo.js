class Package {
  constructor(name, sources, requiredBy) {
    this.name = name;
    this.sources = sources;
    this.requiredBy = requiredBy;
  }
}

// utility classes to generate HTML
function th(content) {
  return `<th>${content}</th>`;
}
function tableHead() {
  let content = '';
  for (let i = 0; i < arguments.length; i++) {
    content += th(arguments[i]);
  }
  return `
    <thead>
      ${row(content)}
    </thead>`;
}
function col(htmlContent, styleClass) {
  return `<td class="${styleClass}">${htmlContent}</td>`;
}
function row(htmlContent) {
  return `<tr>${htmlContent}</tr>`;
}

// main
function normalizeData() {
  var rawData = $('#build-info-raw-data').text();

  // relevant entities to compute on
  const _PACKAGES = [];
  const _DISTINCT_SOURCES = new Set();
  let _DIRECT_DEPENDENCIES;

  // encoding and shaping newline properly
  var normalizedData = rawData.replace(/\\n/g, '\n');
  normalizedData = normalizedData.replace(/\",/g, '",\n');

  const errorMessage = normalizedData.match(/\"error\"\=\>\"(.*)\"/)[1];
  $('#error-message').text(errorMessage); // summary

  _DIRECT_DEPENDENCIES = normalizedData.match(/expand args: (.*)/)[1].split(' ');
  $('#count-direct-dependencies').text(_DIRECT_DEPENDENCIES.length); // summary

  // populate the dependencies table
  $('#dependency-relationship').html(() => {
    let chainedDependenciesHtml = `<table>${tableHead('who', 'requires', 'what', 'from')}`;
    normalizedData.match(/added (.*) because of (.*)/g)
      .forEach(element => {
        const matchingGroupsForAddedPackages = element.match(/added (.*) because of (.*)/);
        if (matchingGroupsForAddedPackages.length > 0) {
          const extendedPackageName = matchingGroupsForAddedPackages[1];
          const pkgName = extendedPackageName.split('@')[0];
          const pkgSource = extendedPackageName.split('@')[1];
          const requiredBy = matchingGroupsForAddedPackages[2];//.replace('(direct):', '');

          // deduplicate packages
          if (_PACKAGES.filter(p => p.name === pkgName).length > 0) {
            const package = _PACKAGES.find(p => p.name === pkgName);
            package.requiredBy.push(requiredBy);
            package.sources.push(pkgSource);
          }
          else {
            _PACKAGES.push(new Package(pkgName, [pkgSource], [requiredBy]));
          }

          _DISTINCT_SOURCES.add(pkgSource); // keep track of distinct sources

          chainedDependenciesHtml +=
            row(
              (_DIRECT_DEPENDENCIES.includes(requiredBy) ? col(`<strong>${requiredBy}</strong>`) : col(requiredBy)) +
              col('-->', 'text-center') +
              col(pkgName) +
              col(`<span class="text-info">${pkgSource}</span>`)
            );
        }
    });
    if (_PACKAGES.length == 0) {
      chainedDependenciesHtml += row(col('no packages found'));
    }
    chainedDependenciesHtml += '</table>';
    return chainedDependenciesHtml;
  });
  $('#count-total-dependencies').text(_PACKAGES.length); // summary

  // populate project sources and packages
  $('#sources').html(() => {
    let sourcesHtml = '';
    _DISTINCT_SOURCES.forEach(source => {
      const packagesSubset = _PACKAGES.filter(p => p.sources.includes(source));
      sourcesHtml += `<div class="text-info source-name collapsed">${source} (${packagesSubset.length})</div>`
      sourcesHtml += `<ul class="source-package-list collapsed">`
      packagesSubset.forEach(package => {
          sourcesHtml += `<li>${package.name}</li>`
        });
        sourcesHtml += `</ul>`;
    });
    return sourcesHtml;
  });

  // `on click` events
  $('.source-name').on('click', function() {
    $(this).toggleClass('collapsed');
    $(this).next('.source-package-list').toggleClass('collapsed');
  });
  $('#show-raw-data').on('click', function() {
    $('#build-info-raw-data').toggleClass('collapsed');
    $('#build-info-raw-data').hasClass('collapsed') ?
      $(this).text('show raw data') :
      $(this).text('hide raw data');
  });
}
