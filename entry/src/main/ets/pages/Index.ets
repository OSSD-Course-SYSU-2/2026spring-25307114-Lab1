import { promptAction } from '@kit.ArkUI';
import { multiDeviceSync } from '../common/MultiDeviceSync';

interface Point {
  x: number;
  y: number;
}

interface SnakeGameSnapshot {
  snake: Point[];
  food: Point;
  dir: Point;
  nextDir: Point;
  isGameOver: boolean;
  isPaused: boolean;
  score: number;
}

const SNAKE_GAME_STATE_KEY = 'snake_game_state';

@Entry
@Component
struct SnakeGame {
  readonly GRID_SIZE: number = 16;
  readonly CELL_COUNT: number = 20;
  readonly SPEED: number = 320;

  @State snake: Point[] = [];
  @State food: Point = { x: 0, y: 0 };
  @State dir: Point = { x: 1, y: 0 };
  @State nextDir: Point = { x: 1, y: 0 };
  @State isGameOver: boolean = false;
  @State isPaused: boolean = false;
  @State score: number = 0;
  @State lastEatTip: string = '';

  private gameTimer: number | null = null;
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D();

  build() {
    Column({ space: 10 }) {
      this.Header()
      this.GameBoard()
      this.ControlPanel()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18, top: 14, bottom: 10 })
    .backgroundColor('#F3F7FB')
    .onKeyEvent((event: KeyEvent) => {
      if (event.keyCode === 2001) {
        this.setDirection(0, -1);
      } else if (event.keyCode === 2002) {
        this.setDirection(0, 1);
      } else if (event.keyCode === 2003) {
        this.setDirection(-1, 0);
      } else if (event.keyCode === 2004) {
        this.setDirection(1, 0);
      }
    })
    .onAppear(() => {
      const restored = this.restoreGameState();
      if (!restored && this.snake.length === 0) {
        this.initGame();
      } else if (!this.isGameOver && !this.isPaused) {
        this.startGame();
      }
      this.drawGame();
    })
    .onDisAppear(() => this.stopGame());
  }

  @Builder
  private Header() {
    Column({ space: 8 }) {
      Text('贪吃蛇')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#162033')

      Row() {
        Column({ space: 4 }) {
          Text('分数')
            .fontSize(12)
            .fontColor('#6C778A')
          Text(`${this.score}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1677FF')
        }
        .width('31%')
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(8)

        Column({ space: 4 }) {
          Text('速度')
            .fontSize(12)
            .fontColor('#6C778A')
          Text(`${this.SPEED}ms`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1677FF')
        }
        .width('31%')
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(8)

        Column({ space: 4 }) {
          Text('状态')
            .fontSize(12)
            .fontColor('#6C778A')
          Text(this.statusText())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1677FF')
        }
        .width('31%')
        .height(56)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  @Builder
  private GameBoard() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.context)
        .width(this.GRID_SIZE * this.CELL_COUNT)
        .height(this.GRID_SIZE * this.CELL_COUNT)
        .backgroundColor('#FFFFFF')
        .border({ width: 2, color: '#25324A' })
        .borderRadius(8)
        .onAreaChange(() => {
          this.drawGame();
        })

      if (this.isGameOver || this.isPaused) {
        Column({ space: 8 }) {
          Text(this.isGameOver ? '游戏结束' : '已暂停')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isGameOver ? '#D93026' : '#1677FF')
          Text(this.isGameOver ? '点击重新开始再挑战一次' : '点击继续回到当前局')
            .fontSize(15)
            .fontColor('#5E6675')
        }
        .width(238)
        .padding(14)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }
    }
    .width('100%')
    .height(this.GRID_SIZE * this.CELL_COUNT + 4)
  }

  @Builder
  private ControlPanel() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Button(this.isPaused ? '继续' : '暂停')
          .width(112)
          .height(40)
          .enabled(!this.isGameOver)
          .onClick(() => {
            if (this.isPaused) {
              this.resumeGame();
            } else {
              this.pauseGame();
            }
          })

        Button('重新开始')
          .width(112)
          .height(40)
          .backgroundColor('#25324A')
          .onClick(() => this.initGame())
      }

      Row({ space: 10 }) {
        Button('同步到多端')
          .width(112)
          .height(38)
          .fontSize(14)
          .backgroundColor('#1677FF')
          .onClick(() => this.pushToOtherDevices())

        Button('读取多端进度')
          .width(112)
          .height(38)
          .fontSize(14)
          .backgroundColor('#38A169')
          .onClick(() => this.pullFromOtherDevices())
      }

      Column({ space: 6 }) {
        this.DirectionButton('↑', 0, -1)
        Row({ space: 22 }) {
          this.DirectionButton('←', -1, 0)
          this.DirectionButton('→', 1, 0)
        }
        this.DirectionButton('↓', 0, 1)
      }
    }
    .width('100%')
  }

  @Builder
  private DirectionButton(label: string, x: number, y: number) {
    Button(label)
      .width(68)
      .height(52)
      .fontSize(24)
      .backgroundColor('#1677FF')
      .enabled(!this.isGameOver)
      .onClick(() => this.setDirection(x, y))
  }

  private statusText(): string {
    if (this.lastEatTip.length > 0) {
      return this.lastEatTip;
    }
    if (this.isGameOver) {
      return '结束';
    }
    if (this.isPaused) {
      return '暂停';
    }
    return '进行中';
  }

  private drawGame(): void {
    const ctx = this.context;
    const boardSize = this.GRID_SIZE * this.CELL_COUNT;
    ctx.clearRect(0, 0, boardSize, boardSize);

    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, boardSize, boardSize);

    ctx.strokeStyle = '#E8EDF3';
    ctx.lineWidth = 1;
    for (let i = 0; i <= this.CELL_COUNT; i++) {
      ctx.beginPath();
      ctx.moveTo(i * this.GRID_SIZE, 0);
      ctx.lineTo(i * this.GRID_SIZE, boardSize);
      ctx.stroke();

      ctx.beginPath();
      ctx.moveTo(0, i * this.GRID_SIZE);
      ctx.lineTo(boardSize, i * this.GRID_SIZE);
      ctx.stroke();
    }

    this.snake.forEach((p, index) => {
      ctx.fillStyle = index === 0 ? '#1677FF' : '#38C172';
      ctx.fillRect(
        p.x * this.GRID_SIZE + 2,
        p.y * this.GRID_SIZE + 2,
        this.GRID_SIZE - 4,
        this.GRID_SIZE - 4
      );
    });

    ctx.fillStyle = '#F04438';
    ctx.fillRect(
      this.food.x * this.GRID_SIZE + 3,
      this.food.y * this.GRID_SIZE + 3,
      this.GRID_SIZE - 6,
      this.GRID_SIZE - 6
    );
  }

  private initGame(): void {
    this.snake = [
      { x: 8, y: 10 },
      { x: 7, y: 10 },
      { x: 6, y: 10 }
    ];
    this.dir = { x: 1, y: 0 };
    this.nextDir = { x: 1, y: 0 };
    this.score = 0;
    this.isGameOver = false;
    this.isPaused = false;
    this.randomFood();
    this.drawGame();
    this.saveGameState();
    this.startGame();
  }

  private startGame(): void {
    this.stopGame();
    this.gameTimer = setInterval(() => {
      this.moveSnake();
      this.drawGame();
    }, this.SPEED);
  }

  private pauseGame(): void {
    if (this.isGameOver) {
      return;
    }
    this.isPaused = true;
    this.stopGame();
    this.saveGameState();
  }

  private resumeGame(): void {
    if (this.isGameOver) {
      return;
    }
    this.isPaused = false;
    this.saveGameState();
    this.startGame();
  }

  private stopGame(): void {
    if (this.gameTimer !== null) {
      clearInterval(this.gameTimer);
      this.gameTimer = null;
    }
  }

  private moveSnake(): void {
    if (this.isGameOver || this.isPaused || this.snake.length === 0) {
      return;
    }

    this.dir = this.nextDir;
    const head: Point = {
      x: this.snake[0].x + this.dir.x,
      y: this.snake[0].y + this.dir.y
    };

    if (head.x < 0 || head.x >= this.CELL_COUNT || head.y < 0 || head.y >= this.CELL_COUNT) {
      this.endGame();
      return;
    }

    for (let p of this.snake) {
      if (p.x === head.x && p.y === head.y) {
        this.endGame();
        return;
      }
    }

    if (head.x === this.food.x && head.y === this.food.y) {
      this.snake = [head, ...this.snake];
      this.score = this.score + 10;
      this.lastEatTip = '+10';
      this.randomFood();
    } else {
      this.snake = [head, ...this.snake.slice(0, this.snake.length - 1)];
      this.lastEatTip = '';
    }
    this.saveGameState();
  }

  private randomFood(): void {
    const emptyCells: Point[] = [];
    for (let x = 0; x < this.CELL_COUNT; x++) {
      for (let y = 0; y < this.CELL_COUNT; y++) {
        const occupied = this.snake.some((p: Point) => p.x === x && p.y === y);
        if (!occupied) {
          emptyCells.push({ x, y });
        }
      }
    }

    if (emptyCells.length === 0) {
      this.endGame();
      return;
    }

    const index = Math.floor(Math.random() * emptyCells.length);
    this.food = emptyCells[index];
  }

  private setDirection(x: number, y: number): void {
    if (this.isGameOver || this.isPaused) {
      return;
    }
    if (this.dir.x === -x && this.dir.y === -y) {
      return;
    }
    this.nextDir = { x, y };
    this.saveGameState();
  }

  private endGame(): void {
    this.isGameOver = true;
    this.isPaused = false;
    this.stopGame();
    this.saveGameState();
  }

  private saveGameState(): void {
    const snapshot: SnakeGameSnapshot = {
      snake: this.snake,
      food: this.food,
      dir: this.dir,
      nextDir: this.nextDir,
      isGameOver: this.isGameOver,
      isPaused: this.isPaused,
      score: this.score
    };
    AppStorage.setOrCreate<string>(SNAKE_GAME_STATE_KEY, JSON.stringify(snapshot));
  }

  private async pushToOtherDevices(): Promise<void> {
    this.pauseGame();
    const state = AppStorage.get<string>(SNAKE_GAME_STATE_KEY);
    if (!state) {
      promptAction.showToast({ message: '当前没有可同步的游戏进度' });
      return;
    }

    try {
      await multiDeviceSync.pushGameState(state);
      promptAction.showToast({ message: '当前局面已同步到多端' });
    } catch (err) {
      promptAction.showToast({ message: '同步失败，请检查多设备连接' });
    }
  }

  private async pullFromOtherDevices(): Promise<void> {
    try {
      const state = await multiDeviceSync.pullGameState();
      if (!state) {
        promptAction.showToast({ message: '暂未读取到其他设备的进度' });
        return;
      }

      AppStorage.setOrCreate<string>(SNAKE_GAME_STATE_KEY, state);
      if (!this.restoreGameState()) {
        promptAction.showToast({ message: '同步进度格式无效' });
        return;
      }

      this.stopGame();
      this.drawGame();
      promptAction.showToast({ message: '已读取多端游戏进度' });
    } catch (err) {
      promptAction.showToast({ message: '读取失败，请稍后重试' });
    }
  }

  private restoreGameState(): boolean {
    const rawState = AppStorage.get<string>(SNAKE_GAME_STATE_KEY);
    if (!rawState) {
      return false;
    }

    try {
      const snapshot: SnakeGameSnapshot = JSON.parse(rawState) as SnakeGameSnapshot;
      if (!snapshot.snake || snapshot.snake.length === 0) {
        return false;
      }

      this.snake = snapshot.snake;
      this.food = snapshot.food;
      this.dir = snapshot.dir;
      this.nextDir = snapshot.nextDir;
      this.isGameOver = snapshot.isGameOver;
      this.isPaused = snapshot.isPaused;
      this.score = snapshot.score;
      return true;
    } catch (err) {
      AppStorage.setOrCreate<string>(SNAKE_GAME_STATE_KEY, '');
      return false;
    }
  }
}
