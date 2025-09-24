// 卡片UI业务逻辑服务
import { CardService, Card, CardStyle } from './CardService';
import { Quote } from '../common/QuoteData';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wallpaper } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

// 卡片导出参数
export interface CardExportParams {
  setAsLockScreen: boolean;
  saveToGallery: boolean;
  context: common.UIAbilityContext;
}

// 卡片操作结果
export interface CardOperationResult {
  success: boolean;
  message: string;
  lockScreenSuccess?: boolean;
  gallerySuccess?: boolean;
}

export class CardUIService {

  /**
   * 获取卡片的背景颜色
   */
  static getCardBackgroundColor(card: Card | null): string {
    if (card?.style?.backgroundColor) {
      return card.style.backgroundColor;
    }
    return '#2c3e50'; // 默认背景色
  }

  /**
   * 根据页面索引获取对应卡片的背景颜色
   */
  static getBackgroundColorForPage(index: number, cardList: (Card | null)[]): string {
    const card = cardList.length > index ? cardList[index] : null;
    return CardUIService.getCardBackgroundColor(card);
  }

  /**
   * 导出卡片（设置锁屏和/或保存到相册）
   */
  static async exportCard(params: CardExportParams): Promise<CardOperationResult> {
    if (!params.setAsLockScreen && !params.saveToGallery) {
      return {
        success: false,
        message: '未选择任何操作'
      };
    }

    try {
      console.log('开始导出卡片操作...');

      // 如果需要保存到相册，先请求权限
      if (params.saveToGallery) {
        const permissionResult = await CardUIService.requestGalleryPermissions(params.context);
        if (!permissionResult.success) {
          return permissionResult;
        }
      }

      // 截图并处理
      return await CardUIService.captureAndExportCard(params);

    } catch (error) {
      console.error('导出卡片失败:', error);
      return {
        success: false,
        message: '导出卡片失败'
      };
    }
  }

  /**
   * 请求相册权限
   */
  private static async requestGalleryPermissions(context: common.UIAbilityContext): Promise<CardOperationResult> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = [
      'ohos.permission.WRITE_IMAGEVIDEO',
      'ohos.permission.READ_IMAGEVIDEO'
    ];

    try {
      // 请求权限
      const data = await atManager.requestPermissionsFromUser(context, permissions);
      console.log('权限请求结果:', data);

      // 检查权限是否都被授予
      const grantStatus: Array<number> = data.authResults;
      const length: number = grantStatus.length;
      let allGranted: boolean = true;

      for (let i = 0; i < length; i++) {
        if (grantStatus[i] !== 0) {
          allGranted = false;
          console.error(`权限 ${permissions[i]} 被拒绝，状态码: ${grantStatus[i]}`);
        }
      }

      if (!allGranted) {
        console.error('用户拒绝了必要的权限');
        return {
          success: false,
          message: '需要存储权限才能保存图片，请到设置中开启'
        };
      }

      console.log('所有权限已授权');
      return { success: true, message: '' };

    } catch (err) {
      const error = err as BusinessError;
      console.error(`请求权限失败. Code is ${error.code}, message is ${error.message}`);
      return {
        success: false,
        message: '请求权限失败'
      };
    }
  }

  /**
   * 截图并导出卡片
   */
  private static async captureAndExportCard(params: CardExportParams): Promise<CardOperationResult> {
    return new Promise((resolve) => {
      // 使用componentSnapshot API截图纯净卡片区域
      componentSnapshot.get("pureCardArea", async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("截图失败: " + JSON.stringify(error));
          resolve({
            success: false,
            message: '截图失败'
          });
          return;
        }

        try {
          // 保存为临时文件
          const tempImagePath = await CardUIService.savePixelMapToTempFile(
            pixelMap,
            params.context
          );

          // 执行导出操作
          const result = await CardUIService.performExportOperations(
            tempImagePath,
            params
          );

          // 清理临时文件
          try {
            await fs.unlink(tempImagePath);
          } catch (unlinkError) {
            console.error('清理临时文件失败:', unlinkError);
          }

          // 释放资源
          pixelMap.release();

          resolve(result);

        } catch (packError) {
          console.error('图片处理失败:', packError);
          pixelMap.release();
          resolve({
            success: false,
            message: '图片处理失败'
          });
        }
      });
    });
  }

  /**
   * 将PixelMap保存为临时文件
   */
  private static async savePixelMapToTempFile(
    pixelMap: image.PixelMap,
    context: common.UIAbilityContext
  ): Promise<string> {
    // 将PixelMap保存为JPEG格式
    const packOpts: image.PackingOption = {
      format: "image/jpeg",
      quality: 98
    };

    const imagePacker: image.ImagePacker = image.createImagePacker();
    const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

    // 创建临时文件
    const filesDir: string = context.filesDir;
    const tempImagePath = `${filesDir}/temp_card_${Date.now()}.jpg`;

    // 保存临时文件
    const file = await fs.open(tempImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    await fs.write(file.fd, arrayBuffer);
    await fs.close(file.fd);

    // 释放图片打包器
    imagePacker.release();

    return tempImagePath;
  }

  /**
   * 执行导出操作
   */
  private static async performExportOperations(
    imagePath: string,
    params: CardExportParams
  ): Promise<CardOperationResult> {
    let lockScreenSuccess = false;
    let gallerySuccess = false;
    let messages: string[] = [];

    // 设置锁屏壁纸
    if (params.setAsLockScreen) {
      lockScreenSuccess = await CardUIService.setAsLockScreenWallpaper(imagePath, params.context);
      messages.push(lockScreenSuccess ? '锁屏壁纸设置成功！' : '锁屏壁纸设置失败！');
    }

    // 保存到相册
    if (params.saveToGallery) {
      gallerySuccess = await CardUIService.saveImageToGallery(imagePath, params.context);
      messages.push(gallerySuccess ? '图片已保存到图库！' : '图片保存到图库失败！');
    }

    const success = (!params.setAsLockScreen || lockScreenSuccess) &&
                   (!params.saveToGallery || gallerySuccess);

    return {
      success,
      message: messages.join('\n'),
      lockScreenSuccess,
      gallerySuccess
    };
  }

  /**
   * 设置为锁屏壁纸
   */
  private static async setAsLockScreenWallpaper(
    imagePath: string,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      console.log('Setting lock screen wallpaper:', imagePath);

      // 检查SET_WALLPAPER权限
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        'ohos.permission.SET_WALLPAPER'
      );

      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.warn('SET_WALLPAPER permission not granted, status:', grantStatus);
      } else {
        console.log('SET_WALLPAPER permission granted');
      }

      // 验证文件是否存在
      try {
        const stat = await fileIo.stat(imagePath);
        console.info("File size: " + stat.size);
      } catch (statError) {
        console.error("File not accessible:", statError);
        throw new Error('Card file not accessible');
      }

      // 设置锁屏壁纸
      console.log('Calling wallpaper.setWallpaper with type WALLPAPER_LOCKSCREEN');
      await wallpaper.setWallpaper(imagePath, wallpaper.WallpaperType.WALLPAPER_LOCKSCREEN);

      console.log('Lock screen wallpaper set successfully');
      return true;
    } catch (error) {
      console.error('Failed to set lock screen wallpaper:', error);
      return false;
    }
  }

  /**
   * 保存图片到相册
   */
  private static async saveImageToGallery(
    imagePath: string,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      console.log('Saving image to gallery:', imagePath);

      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      // 读取源文件内容
      const sourceFile = await fileIo.open(imagePath, fileIo.OpenMode.READ_ONLY);
      const stat = await fileIo.stat(imagePath);
      const buffer = new ArrayBuffer(stat.size);
      await fileIo.read(sourceFile.fd, buffer);
      await fileIo.close(sourceFile);

      // 写入到相册
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.write(file.fd, buffer);
      await fileIo.close(file.fd);

      console.log('Image saved to gallery successfully:', uri);
      return true;
    } catch (error) {
      console.error('Failed to save image to gallery:', error);
      return false;
    }
  }

  /**
   * 生成卡片快照（用于预览）
   */
  static async generateCardSnapshot(
    componentId: string,
    context: common.UIAbilityContext
  ): Promise<string | null> {
    return new Promise((resolve) => {
      componentSnapshot.get(componentId, async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("生成卡片快照失败:", error);
          resolve(null);
          return;
        }

        try {
          const tempPath = await CardUIService.savePixelMapToTempFile(pixelMap, context);
          pixelMap.release();
          resolve(tempPath);
        } catch (err) {
          console.error("保存快照失败:", err);
          pixelMap.release();
          resolve(null);
        }
      });
    });
  }
}