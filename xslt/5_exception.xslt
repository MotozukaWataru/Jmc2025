<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <!--
    【5_exception.xslt の目的】

    4_technique.xslt までで得られた構造に対して、
    unit の相対的な長さを表す補助情報を付与する。

    1. half / double の付与
       - 親が <seg type="multi"> の unit を対象とする。
       - その multi の中に含まれる unit の個数と位置に応じて、
         つぎのように @subtype を追加する。

         * unit が 1 つだけの multi:
             その unit に subtype="double" を付与
         * unit が 3 つの multi:
             2 番目と 3 番目の unit に subtype="half" を付与

       - すでに @subtype がある場合（例: "ka"）には、
         既存の値に追記するかたちで "ka half" などと記録する。
  -->
  
  <!-- [共通] 元のノード構造を保ってコピーする（デフォルト動作） -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- ==============================
       unit に half / double を付与
       ============================== -->
  <xsl:template match="tei:seg[@type='unit']">
    
    <!-- 親 multi と、その中の unit 一覧 -->
    <xsl:variable name="multi"  select="parent::tei:seg[@type='multi']"/>
    <xsl:variable name="units"  select="$multi/tei:seg[@type='unit']"/>
    <xsl:variable name="nUnits" select="count($units)"/>
    
    <!-- この unit が multi 内で何番目か（1 始まり） -->
    <xsl:variable name="pos"
      select="count(preceding-sibling::tei:seg[@type='unit']) + 1"/>
    
    <!-- この unit が ka を含むかどうか（半角スペース区切りで判定） -->
    <xsl:variable name="hasKa"
      select="contains(concat(' ', @subtype, ' '), ' ka ')"/>
    
    <!-- この unit 内の小譜字（legato）の数 -->
    <xsl:variable name="legatoCount"
      select="count(.//tei:g[@type='legato'])"/>
    
    <!-- half / double の付与判定（既に ka を持つものは half 対象から除外） -->
    <xsl:variable name="extraSubtype">
      <xsl:choose>
        <!-- multi に unit が 1 つ かつ 小譜字が 4 つ → double -->
        <xsl:when test="$nUnits = 1 and $legatoCount = 4">
          <xsl:text>double</xsl:text>
        </xsl:when>
        
        <!-- multi に unit が 3 つ → 2番目・3番目の unit に half
             ただし、既に subtype に ka を含む unit は除外する -->
        <xsl:when test="$nUnits = 3 and $pos &gt;= 2 and not($hasKa)">
          <xsl:text>half</xsl:text>
        </xsl:when>
        
        <!-- それ以外のケースでは付与しない -->
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:copy>
      <!-- 既存属性はそのままコピー -->
      <xsl:copy-of select="@*"/>
      
      <!-- subtype がまだ無く、extraSubtype がある場合だけ新規付与 -->
      <xsl:if test="not(@subtype) and string($extraSubtype) != ''">
        <xsl:attribute name="subtype">
          <xsl:value-of select="$extraSubtype"/>
        </xsl:attribute>
      </xsl:if>
      
      <!-- 子ノード（g / note / 掻洗 など）はそのまま通す -->
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>



