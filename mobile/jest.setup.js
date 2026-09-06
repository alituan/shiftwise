// Required for react-native-reanimated / react-native-worklets under Jest --
// both are native libraries; without this, importing them throws at
// require-time. Order matters: the worklets mock must be registered before
// reanimated's setUpTests() runs. See:
//   https://docs.swmansion.com/react-native-worklets/docs/guides/testing/
//   https://docs.swmansion.com/react-native-reanimated/docs/guides/testing/
jest.mock('react-native-worklets', () => require('react-native-worklets/lib/module/mock'));
require('react-native-reanimated').setUpTests();
require('react-native-gesture-handler/jestSetup');
