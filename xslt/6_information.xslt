<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!--
    【6_information.xslt の目的】

    1) <encodingDesc>/<editorialDecl> の記述を
       「整形XML と XSLT チェーンの説明」に差し替える。
    2) <profileDesc>/<textClass>/<catRef/@target> に記録した
       調子・拍子分類（#ritsu / #ryo / #sandobyoshi / #gohyoshi）を
       <div type="piece"> の @ana にコピーする。
    3) タイトルの「書誌XML」を「整形XML」に差し替える。
  -->

  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ========================================
       [1] editorialDecl を整形XML用の説明に差し替え
       ======================================== -->

  <xsl:template match="tei:editorialDecl">
    <!-- 出力側では editorialDecl に TEI 名前空間をデフォルト指定 -->
    <editorialDecl xmlns="http://www.tei-c.org/ns/1.0">
      <!-- もとの属性（もしあれば）をコピー -->
      <xsl:apply-templates select="@*"/>

      <!-- 新しい説明 -->
      <p>整形XML：書誌XMLを元にし，Python で XSLT をあてて自動生成する。</p>
      <p>利用した XSLT は以下の 7 つ。</p>
      <p>- 0_preprocess.xslt（整理・並び替え）</p>
      <p>- 1_seg_cycle.xslt（百ごとに区切る）</p>
      <p>- 2_seg_multi.xslt（楽句点ごとに区切る）</p>
      <p>- 3_seg_unit.xslt（琵琶の一撥絃単位で区切る）</p>
      <p>- 4_technique.xslt（琵琶の基本奏法に関する調整）</p>
      <p>- 5_exception.xslt（例外処理）</p>
      <p>- 6_information.xslt（整形XML、曲に関する情報付与）</p>
    </editorialDecl>
  </xsl:template>

  <!-- ==============================
       [2] 調子・拍子分類を piece/@ana にコピー
       ============================== -->

  <!-- ヘッダ側の catRef/@target を参照 -->
  <xsl:variable name="pieceAna" select="
      normalize-space(
      /tei:TEI
      /tei:teiHeader
      /tei:profileDesc
      /tei:textClass
      /tei:catRef[1]/@target
      )"/>

  <xsl:template match="tei:div[@type = 'piece']">
    <xsl:copy>
      <!-- 既存属性 -->
      <xsl:apply-templates select="@*"/>

      <!-- ana が未設定で，ヘッダ側に分類情報があれば付与 -->
      <xsl:if test="not(@ana) and string($pieceAna) != ''">
        <xsl:attribute name="ana">
          <xsl:value-of select="$pieceAna"/>
        </xsl:attribute>
      </xsl:if>

      <!-- 子ノードはそのまま -->
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       [3] タイトルの「書誌XML」を「整形XML」に差し替え
       ============================== -->
  <xsl:template match="tei:title[contains(., '書誌XML')]">
    <xsl:copy>
      <!-- 既存の属性はそのまま -->
      <xsl:apply-templates select="@*"/>
      
      <!-- 「書誌XML」より前の部分をそのまま出力 -->
      <xsl:value-of select="substring-before(., '書誌XML')"/>
      
      <!-- ここだけ置き換える -->
      <xsl:text>整形XML</xsl:text>
      
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>



