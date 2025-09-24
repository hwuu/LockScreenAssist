// 卡片查看器数据源管理类
import { Card } from '../services/CardService';

// 数据源类实现，用于LazyForEach
export class CardViewerDataSource implements IDataSource {
  private cards: Card[] = [];
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    return this.cards.length;
  }

  public getData(index: number): Card {
    return this.cards[index];
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  public pushItem(card: Card): void {
    this.cards.push(card);
    this.notifyDataAdd(this.cards.length - 1);
  }

  public addItem(card: Card): void {
    this.cards.unshift(card);
    this.notifyDataAdd(0);
  }

  private notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }

  // 清空所有数据
  public clear(): void {
    const oldCount = this.cards.length;
    this.cards = [];
    // 通知所有数据已删除
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
    console.log(`CardViewerDataSource: 已清空 ${oldCount} 条数据`);
  }
}