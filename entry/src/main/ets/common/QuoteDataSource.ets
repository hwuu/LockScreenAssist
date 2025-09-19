// 名言数据源管理类
import { Quote } from './QuoteData';

// 数据源类实现，参考helper6_page_turn.txt第68-74行
export class QuoteDataSource implements IDataSource {
  private quotes: Quote[] = [];
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    console.log('CLAUDE_DEBUG: QuoteDataSource.totalCount:', this.quotes.length);
    return this.quotes.length;
  }

  public getData(index: number): Quote {
    console.log(`CLAUDE_DEBUG: QuoteDataSource.getData(${index}):`, this.quotes[index]?.text || 'null');
    return this.quotes[index];
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

  public pushItem(quote: Quote): void {
    console.log('CLAUDE_DEBUG: QuoteDataSource.pushItem:', quote?.text || 'null', '总数将变为:', this.quotes.length + 1);
    this.quotes.push(quote);
    this.notifyDataAdd(this.quotes.length - 1);
  }

  public addItem(quote: Quote): void {
    this.quotes.unshift(quote);
    this.notifyDataAdd(0);
  }

  private notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }
}