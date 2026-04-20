interface Point {
  x: number;
  y: number;
}

@Entry
@Component
struct SnakeGame {
  // 游戏配置
  readonly GRID_SIZE: number = 20;
  readonly CELL_COUNT: number = 20;
  readonly SPEED: number = 400; // 已调慢，可自行修改

  // 游戏状态
  @State snake: Point[] = [];
  @State food: Point = { x: 0, y: 0 };
  @State dir: Point = { x: 1, y: 0 };
  @State isGameOver: boolean = false;
  @State score: number = 0;
  gameTimer: number | null = null;

  build() {
    Column() {
      // 标题
      Text(`贪吃蛇 分数：${this.score}`)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin(15);

      // 游戏结束
      if (this.isGameOver) {
        Column() {
          Text("游戏结束")
            .fontSize(40)
            .fontColor(Color.Red);
          Text("点击重新开始")
            .fontSize(22);
        }
        .onClick(() => this.initGame())
        .margin(10);
      }

      // 游戏画布（核心修复：用Canvas绘制，彻底消除黑线）
      Canvas(this.context)
        .width(this.GRID_SIZE * this.CELL_COUNT)
        .height(this.GRID_SIZE * this.CELL_COUNT)
        .backgroundColor('#f5f5f5')
        .border({ width: 2, color: '#333' })
        .onAreaChange(() => {
          this.drawGame(); // 区域变化时重绘
        });

      // 方向按钮
      Column({ space: 5 }) {
        Button("↑")
          .width(60)
          .height(60)
          .onClick(() => this.setDirection(0, -1));
        Row({ space: 20 }) {
          Button("←")
            .width(60)
            .height(60)
            .onClick(() => this.setDirection(-1, 0));
          Button("→")
            .width(60)
            .height(60)
            .onClick(() => this.setDirection(1, 0));
        }
        Button("↓")
          .width(60)
          .height(60)
          .onClick(() => this.setDirection(0, 1));
      }
      .margin(20);
    }
    .width('100%')
    .padding(10)
    .onKeyEvent((event: KeyEvent) => {
      if (event.keyCode === 2001) this.setDirection(0, -1);
      else if (event.keyCode === 2002) this.setDirection(0, 1);
      else if (event.keyCode === 2003) this.setDirection(-1, 0);
      else if (event.keyCode === 2004) this.setDirection(1, 0);
    })
    .onAppear(() => this.initGame())
    .onDisAppear(() => this.stopGame());
  }

  // Canvas上下文
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D();

  // 绘制游戏画面（核心修复逻辑）
  private drawGame(): void {
    const ctx = this.context;
    // 清空画布
    ctx.clearRect(0, 0, this.GRID_SIZE * this.CELL_COUNT, this.GRID_SIZE * this.CELL_COUNT);

    // 1. 绘制背景网格（无黑线版本）
    ctx.strokeStyle = '#e0e0e0';
    ctx.lineWidth = 1;
    for (let i = 0; i <= this.CELL_COUNT; i++) {
      // 竖线
      ctx.beginPath();
      ctx.moveTo(i * this.GRID_SIZE, 0);
      ctx.lineTo(i * this.GRID_SIZE, this.CELL_COUNT * this.GRID_SIZE);
      ctx.stroke();
      // 横线
      ctx.beginPath();
      ctx.moveTo(0, i * this.GRID_SIZE);
      ctx.lineTo(this.CELL_COUNT * this.GRID_SIZE, i * this.GRID_SIZE);
      ctx.stroke();
    }

    // 2. 绘制蛇身
    this.snake.forEach((p, index) => {
      ctx.fillStyle = index === 0 ? '#0066CC' : '#33CC33';
      ctx.fillRect(
        p.x * this.GRID_SIZE + 1, // +1 避开网格线
        p.y * this.GRID_SIZE + 1,
        this.GRID_SIZE - 2, // -2 留出网格线空间
        this.GRID_SIZE - 2
      );
    });

    // 3. 绘制食物
    ctx.fillStyle = '#FF3333';
    ctx.fillRect(
      this.food.x * this.GRID_SIZE + 1,
      this.food.y * this.GRID_SIZE + 1,
      this.GRID_SIZE - 2,
      this.GRID_SIZE - 2
    );
  }

  // 初始化游戏
  initGame(): void {
    this.snake = [
      { x: 8, y: 10 },
      { x: 7, y: 10 },
      { x: 6, y: 10 }
    ];
    this.dir = { x: 1, y: 0 };
    this.score = 0;
    this.isGameOver = false;
    this.randomFood();
    this.startGame();
  }

  // 开始循环
  startGame(): void {
    this.stopGame();
    this.gameTimer = setInterval(() => {
      this.moveSnake();
      this.drawGame(); // 每次移动后重绘
    }, this.SPEED);
  }

  // 停止游戏
  stopGame(): void {
    if (this.gameTimer) {
      clearInterval(this.gameTimer);
      this.gameTimer = null;
    }
  }

  // 移动逻辑
  moveSnake(): void {
    if (this.isGameOver) return;

    const head: Point = { x: this.snake[0].x + this.dir.x, y: this.snake[0].y + this.dir.y };

    // 撞墙
    if (head.x < 0 || head.x >= this.CELL_COUNT || head.y < 0 || head.y >= this.CELL_COUNT) {
      this.isGameOver = true;
      this.stopGame();
      return;
    }

    // 撞自己
    for (let p of this.snake) {
      if (p.x === head.x && p.y === head.y) {
        this.isGameOver = true;
        this.stopGame();
        return;
      }
    }

    this.snake.unshift(head);

    // 吃食物
    if (head.x === this.food.x && head.y === this.food.y) {
      this.score += 10;
      this.randomFood();
    } else {
      this.snake.pop();
    }
  }

  // 随机食物
  randomFood(): void {
    let newFood: Point;
    while (true) {
      newFood = {
        x: Math.floor(Math.random() * this.CELL_COUNT),
        y: Math.floor(Math.random() * this.CELL_COUNT)
      };
      let overlap = false;
      for (let p of this.snake) {
        if (p.x === newFood.x && p.y === newFood.y) {
          overlap = true;
          break;
        }
      }
      if (!overlap) break;
    }
    this.food = newFood;
  }

  // 设置方向（禁止反向）
  setDirection(x: number, y: number): void {
    if (this.dir.x === -x && this.dir.y === -y) return;
    if (this.isGameOver) return;
    this.dir = { x, y };
  }
}