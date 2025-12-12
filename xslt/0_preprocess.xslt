<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!--
    【0_preprocess.xslt の目的】

    催馬楽の書誌 TEI XML に対して、後続の segmentation 用 XSLT を適用しやすくするための前処理を行う。

    1. 音楽分析の対象外となる情報の削除
       - 行区切り <lb/> の削除
       - <metamark> に付与された記号配置・朱墨情報（@rend, @place）の削除

    2. 記譜情報の整理・統合
       - <metamark>一</metamark> <metamark>火</metamark>
         → <metamark>一火</metamark> に統合
       - <hi rend="sub"> 内の <g> を小譜字とみなし、type="legato" を付与
       - 歌詞 (<note>) と 小譜字 / 拍子記号（火・一・一火 など）の並び順を整える
         （1 unit の内部での順序をそろえるため）
  -->
    
    <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- [1] 行区切り <lb/> を削除 -->
    <xsl:template match="tei:lb"/>
    
    <!-- [2] <metamark> の配置情報 @rend / @place を削除 -->
    <xsl:template match="tei:metamark/@rend | tei:metamark/@place"/>
    
    <!--
    [3] 拍子記号の統合
        <metamark>一</metamark> に続けて <metamark>火</metamark> が来る場合、
        「一火」としてひとつの <metamark> にまとめる。
  -->
    <xsl:template match="tei:metamark[text()='一']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <!-- 直後が <metamark>火</metamark> のときだけ「一火」にする -->
                <xsl:when test="following-sibling::*[1][self::tei:metamark and text()='火']">
                    <xsl:text>一火</xsl:text>
                </xsl:when>
                <!-- それ以外は元の内容をそのまま出力 -->
                <xsl:otherwise>
                    <xsl:apply-templates select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <!-- [3-補] 直前が「一」の <metamark>火</metamark> は統合済みなので削除 -->
    <xsl:template
        match="tei:metamark[text()='火'
        and preceding-sibling::*[1][self::tei:metamark and text()='一']]"/>
    
    <!--
    [4] 小譜字の明示化
        <hi rend="sub"> 内にある <g> を小譜字とみなし、
        type="legato" を付与する。
  -->
    <xsl:template match="tei:hi[@rend='sub']/tei:g">
        <xsl:copy>
            <!-- 既存属性のうち @type は除外 -->
            <xsl:copy-of select="@*[local-name() != 'type']"/>
            <xsl:attribute name="type">legato</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!--
    [5] <hi rend="sub"> 自体は構造として保持せず、中身だけを残す
        （小譜字 <g> 自体は上のテンプレートで処理される）
  -->
    <xsl:template match="tei:hi[@rend='sub']">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- ==============================
       [6] 歌詞と小譜字・拍子記号の並び替え
       ============================== -->
       
    <!--
       後続の segmentation（例：<seg type="unit">）で扱いやすいように、
       1 unit の内部での出現順をそろえる。
    
       1 unit 内では、
         大譜字<g>→ 小譜字<g type="legato"> 
         → 歌詞 <note> → 記号（<metamark>火・一・一火 など）の順に並べる。
          
       具体的には、note の直後にある <hi rend="sub"> の中身を以下の通り再配置する。   
      
        - 小譜字 g は note の前に、
        - それ以外（火などの <metamark>）は note の後ろに
    -->
  
  <xsl:template match="tei:note[following-sibling::*[1][self::tei:hi[@rend='sub']]]">
    <!-- 直後の <hi rend="sub"> を取得 -->
    <xsl:variable name="hi" select="following-sibling::*[1]"/>
    
    <!-- 1) 先に hi の中の g（小譜字） -->
    <xsl:apply-templates select="$hi/tei:g"/>
    
    <!-- 2) note 自身 -->
    <xsl:copy>
      <xsl:copy-of select="@* | node()"/>
    </xsl:copy>
    
    <!-- 3) 最後に hi の中の g 以外（火など） -->
    <xsl:apply-templates select="$hi/node()[not(self::tei:g)]"/>
  </xsl:template>
    
    <!--
    [7] 直前が <note> の <hi rend="sub"> は、
        上記 [6] で中身をすでに出力済みなので、ここでは出力しない。
  -->
    <xsl:template match="tei:hi[@rend='sub'][preceding-sibling::*[1][self::tei:note]]"/>
    
</xsl:stylesheet>



