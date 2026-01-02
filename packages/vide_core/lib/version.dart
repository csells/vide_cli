/// Current version of Vide CLI
///
/// Set at compile time via: dart compile exe -DVIDE_VERSION=x.y.z
/// Falls back to '0.0.0-dev' for local development builds.
const String videVersion = String.fromEnvironment(
  'VIDE_VERSION',
  defaultValue: '0.0.0-dev',
);

/// GitHub repository owner
const String githubOwner = 'Norbert515';

/// GitHub repository name
const String githubRepo = 'vide_cli';
