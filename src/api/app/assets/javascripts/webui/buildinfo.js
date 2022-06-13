class Package {
  constructor(name, sources, requiredBy) {
    this.name = name;
    this.sources = sources;
    this.requiredBy = requiredBy;
  }
}

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

function normalizeData() {
  var rawData = $('#build-info-raw-data').text();

  // encoding and shaping newline properly
  var normalizedData = rawData.replace(/\\n/g, '\n');
  normalizedData = normalizedData.replace(/\",/g, '",\n');

  const errorMessage = normalizedData.match(/\"error\"\=\>\"(.*)\"/)[1];
  $('#error-message').text(errorMessage);

  const directDependencies = normalizedData.match(/expand args: (.*)/)[1].split(' ');
  $('#count-direct-dependencies').text(directDependencies.length);

  const packages = [];
  const distinctSources = new Set();
  $('#dependency-relationship').html(() => {
    let chainedDependencies =
      `<table>${tableHead('who', 'requires', 'what', 'from')}`;
    normalizedData.match(/added (.*) because of (.*)/g).forEach(element => {
      const matchingGroups = element.match(/added (.*) because of (.*)/);
      const extendedPackageName = matchingGroups[1];
      const pkgName = extendedPackageName.split('@')[0];
      const pkgSource = extendedPackageName.split('@')[1];
      const requiredBy = matchingGroups[2];//.replace('(direct):', '');

      if (packages.filter(p => p.name === pkgName).length > 0) {
        const package = packages.find(p => p.name === pkgName);
        package.requiredBy.push(requiredBy);
        package.sources.push(pkgSource);
      }
      else {
        packages.push(new Package(pkgName, [pkgSource], [requiredBy]));
      }

      distinctSources.add(pkgSource);

      chainedDependencies +=
        row(
          (directDependencies.includes(requiredBy) ?
            col(`<strong>${requiredBy}</strong>`) : col(requiredBy)) +
          col('-->', 'text-center') +
          col(pkgName) +
          col(`<span class="badge badge-primary">${pkgSource}</span>`)
        );
    });
    chainedDependencies += '</table>';
    return chainedDependencies;
  });
  $('#count-total-dependencies').text(packages.length);

  $('#sources').html(() => {
    let sourcesHtml = '';
    distinctSources.forEach(source => {
      const packagesSubset = packages.filter(p => p.sources.includes(source));
      sourcesHtml += `<div class="font-weight-bold source-name collapsed">${source} (${packagesSubset.length})</div>`
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
