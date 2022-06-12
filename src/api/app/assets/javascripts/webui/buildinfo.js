class Package {
  constructor(name, source, requiredBy) {
    this.name = name;
    this.source = source;
    this.requiredBy = requiredBy;
  }
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
    let chainedDependencies = "";
    normalizedData.match(/added (.*) because of (.*)/g).forEach(element => {
      const matchingGroups = element.match(/added (.*) because of (.*)/);
      const extendedPackageName = matchingGroups[1];
      const pkgName = extendedPackageName.split('@')[0];
      const pkgSource = extendedPackageName.split('@')[1];
      const requiredBy = matchingGroups[2].replace('(direct):', '');

      packages.push(new Package(pkgName, pkgSource, requiredBy));
      distinctRepositories.add(pkgSource);
      const elementHtml = directDependencies.includes(requiredBy) ?
        '<code><u>' + requiredBy + '</u></code> <i>requires</i> <code>' + pkgName + '</code> <small class="badge badge-primary">' + pkgSource + '</small>' :
        '<code>' + requiredBy + '</code> <i>requires</i> <code>' + pkgName + '</code> <small class="badge badge-primary">' + pkgSource + '</small>';
      chainedDependencies += '<div>' + elementHtml + '</div>';
    });
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
