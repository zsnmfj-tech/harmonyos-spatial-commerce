/**
 * 入口页 = 底部 Tab 壳。对应地基计划 Task 9。
 */
import { TabBar } from '../components/TabBar';

@Entry
@Component
struct Index {
  build() {
    Column() {
      TabBar();
    }
    .width('100%')
    .height('100%');
  }
}
