import {
  abilityAccessCtrl,
  AbilityConstant,
  ConfigurationConstant,
  Permissions,
  UIAbility,
  Want
} from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { multiDeviceSync } from '../common/MultiDeviceSync';

const DOMAIN = 0x0000;
const SNAKE_GAME_STATE_KEY = 'snake_game_state';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreSnakeGameState(want);
    this.prepareMultiDeviceSync();
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreSnakeGameState(want);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    const snakeGameState = AppStorage.get<string>(SNAKE_GAME_STATE_KEY) ?? '';
    wantParam[SNAKE_GAME_STATE_KEY] = snakeGameState;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onContinue');
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private restoreSnakeGameState(want: Want): void {
    const params = want.parameters;
    if (!params) {
      return;
    }

    const snakeGameState = params[SNAKE_GAME_STATE_KEY];
    if (typeof snakeGameState === 'string' && snakeGameState.length > 0) {
      AppStorage.setOrCreate<string>(SNAKE_GAME_STATE_KEY, snakeGameState);
    }
  }

  private async prepareMultiDeviceSync(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = [
        'ohos.permission.DISTRIBUTED_DATASYNC'
      ];
      const result = await atManager.requestPermissionsFromUser(this.context, permissions);
      if (result.authResults[0] !== 0) {
        hilog.warn(DOMAIN, 'multiDevice', '%{public}s', 'Distributed data sync permission was denied.');
        return;
      }
      await multiDeviceSync.init(this.context);
    } catch (err) {
      hilog.error(DOMAIN, 'multiDevice', 'Failed to prepare multi-device sync: %{public}s', JSON.stringify(err));
    }
  }
}
