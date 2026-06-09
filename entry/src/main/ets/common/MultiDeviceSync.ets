import { distributedKVStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const BUNDLE_NAME = 'com.example.myapplication';
const STORE_ID = 'snake_game_multi_device_store';
const GAME_STATE_KEY = 'shared_snake_game_state';

class MultiDeviceSyncService {
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private initializing: Promise<void> | null = null;

  init(context: common.UIAbilityContext): Promise<void> {
    if (this.kvStore) {
      return Promise.resolve();
    }
    if (this.initializing) {
      return this.initializing;
    }

    this.initializing = this.openStore(context);
    return this.initializing;
  }

  async pushGameState(state: string): Promise<void> {
    const store = this.requireStore();
    await store.put(GAME_STATE_KEY, state);
  }

  async pullGameState(): Promise<string | null> {
    const store = this.requireStore();
    try {
      const value = await store.get(GAME_STATE_KEY);
      return typeof value === 'string' ? value : null;
    } catch (err) {
      return null;
    }
  }

  private async openStore(context: common.UIAbilityContext): Promise<void> {
    const config: distributedKVStore.KVManagerConfig = {
      bundleName: BUNDLE_NAME,
      context: context
    };
    const options: distributedKVStore.Options = {
      createIfMissing: true,
      encrypt: false,
      backup: false,
      autoSync: true,
      kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
      securityLevel: distributedKVStore.SecurityLevel.S1
    };

    this.kvManager = distributedKVStore.createKVManager(config);
    this.kvStore =
      await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(STORE_ID, options);
    await this.kvStore.enableSync(true);
  }

  private requireStore(): distributedKVStore.SingleKVStore {
    if (!this.kvStore) {
      throw new Error('Multi-device store is not ready.');
    }
    return this.kvStore;
  }
}

export const multiDeviceSync = new MultiDeviceSyncService();
