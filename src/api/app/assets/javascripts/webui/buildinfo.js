class Package {
  constructor(name, source, requiredBy) {
    this.name = name;
    this.source = source;
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
function col(htmlContent) {
  return `<td>${htmlContent}</td>`;
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
  $('#build-info-error-message').text(errorMessage);

  const directDependencies = normalizedData.match(/expand args: (.*)/)[1].split(' ');
  $('#build-info-direct-dependencies').html(() => {
    let deps = "";
    directDependencies.forEach(element => {
      deps += '<span class="badge badge-secondary">' + element + '</span>&nbsp;'
    });
    return deps;
  });

  const packages = [];
  const distinctRepositories = new Set();
  $('#build-info-chained-dependencies').html(() => {
    let chainedDependencies =
      `<table>${tableHead('package name', 'requires', 'dependency name', 'repository')}`;
    normalizedData.match(/added (.*) because of (.*)/g).forEach(element => {
      const matchingGroups = element.match(/added (.*) because of (.*)/);
      const extendedPackageName = matchingGroups[1];
      const pkgName = extendedPackageName.split('@')[0];
      const pkgSource = extendedPackageName.split('@')[1];
      const requiredBy = matchingGroups[2].replace('(direct):', '');

      packages.push(new Package(pkgName, pkgSource, requiredBy));
      distinctRepositories.add(pkgSource);
      chainedDependencies +=
        row(
          (directDependencies.includes(requiredBy) ?
            col(`<strong>${requiredBy}</strong>`) : col(requiredBy)) +
          col('-->') +
          col(pkgName) +
          col(`<span class="badge badge-primary">${pkgSource}</span>`)
        );
    });
    chainedDependencies += '</table>';
    return chainedDependencies;
  });

  $('#build-info-repositories').html(() => {
    let distinctRepositoriesHtml = '';
    Array.from(distinctRepositories).forEach(repo => {
      distinctRepositoriesHtml += '<div class="badge badge-primary">' + repo + '</div>&nbsp;';
    });
    return distinctRepositoriesHtml;
  });
}
