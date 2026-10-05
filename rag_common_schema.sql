CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS rag;
COMMENT ON SCHEMA rag IS '공용 RAG 문서, 벡터 검색, 평가셋 및 평가 결과를 관리하는 스키마';

CREATE TABLE IF NOT EXISTS rag.collections (
    collections_id BIGSERIAL PRIMARY KEY,
    collection_code TEXT NOT NULL UNIQUE,
    collection_name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rag.collections IS 'RAG 검색 대상을 논리적으로 분리하기 위한 컬렉션 정의 테이블';
COMMENT ON COLUMN rag.collections.collections_id IS '컬렉션 내부 고유 식별자';
COMMENT ON COLUMN rag.collections.collection_code IS '프로그램에서 사용하는 컬렉션 고유 코드';
COMMENT ON COLUMN rag.collections.collection_name IS '화면에 표시할 컬렉션 이름';
COMMENT ON COLUMN rag.collections.description IS '컬렉션의 목적과 데이터 성격에 대한 설명';
COMMENT ON COLUMN rag.collections.is_active IS '컬렉션 사용 여부';
COMMENT ON COLUMN rag.collections.metadata IS '컬렉션별 확장 설정 및 사용자 정의 정보';
COMMENT ON COLUMN rag.collections.created_at IS '최초 생성 일시';
COMMENT ON COLUMN rag.collections.updated_at IS '최종 수정 일시';

CREATE TABLE IF NOT EXISTS rag.documents (
    documents_id BIGSERIAL PRIMARY KEY,
    collections_id BIGINT NOT NULL REFERENCES rag.collections(collections_id),
    source_type TEXT NOT NULL,
    source_name TEXT,
    source_path TEXT,
    source_record_no INTEGER,
    title TEXT,
    content TEXT,
    source_hash TEXT,
    document_version INTEGER NOT NULL DEFAULT 1,
    is_evaluation BOOLEAN NOT NULL DEFAULT FALSE,
    evaluation_set_code TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rag.documents IS 'RAG에 등록되는 원본 데이터를 파일 형식이나 업무 도메인에 관계없이 공통 관리하는 테이블';
COMMENT ON COLUMN rag.documents.documents_id IS '원본 문서 또는 원본 레코드의 고유 식별자';
COMMENT ON COLUMN rag.documents.collections_id IS '문서가 속한 RAG 컬렉션';
COMMENT ON COLUMN rag.documents.source_type IS '원본 유형';
COMMENT ON COLUMN rag.documents.source_name IS '원본 파일명, 데이터셋명 또는 외부 원본 이름';
COMMENT ON COLUMN rag.documents.source_path IS '원본 파일 경로 또는 원본 위치 식별정보';
COMMENT ON COLUMN rag.documents.source_record_no IS '구조화 데이터의 원본 행 번호';
COMMENT ON COLUMN rag.documents.title IS '문서 또는 레코드의 제목';
COMMENT ON COLUMN rag.documents.content IS '원본에서 추출한 대표 본문 또는 원본 레코드 텍스트';
COMMENT ON COLUMN rag.documents.source_hash IS '원본 변경 및 중복 확인을 위한 해시값';
COMMENT ON COLUMN rag.documents.document_version IS '동일 문서의 변경 이력 관리를 위한 버전';
COMMENT ON COLUMN rag.documents.is_evaluation IS '평가셋으로 지정된 데이터인지 여부';
COMMENT ON COLUMN rag.documents.evaluation_set_code IS '평가셋 그룹 코드';
COMMENT ON COLUMN rag.documents.is_active IS '현재 검색 및 서비스에서 사용할 데이터인지 여부';
COMMENT ON COLUMN rag.documents.metadata IS '원본의 추가 속성';
COMMENT ON COLUMN rag.documents.created_at IS '등록 일시';
COMMENT ON COLUMN rag.documents.updated_at IS '최종 수정 일시';

CREATE TABLE IF NOT EXISTS rag.document_chunks (
    document_chunks_id BIGSERIAL PRIMARY KEY,
    documents_id BIGINT NOT NULL REFERENCES rag.documents(documents_id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    page_number INTEGER,
    page_start INTEGER,
    page_end INTEGER,
    block_type TEXT,
    section_title TEXT,
    section_path TEXT,
    chunk_text TEXT NOT NULL,
    chunk_hash TEXT NOT NULL,
    embedding VECTOR({{VECTOR_DIMENSION}}),
    embedding_provider TEXT,
    embedding_model TEXT,
    embedding_dimension INTEGER,
    chunk_strategy TEXT,
    chunk_size INTEGER,
    chunk_overlap INTEGER,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(documents_id, chunk_index)
);
ALTER TABLE rag.document_chunks ADD COLUMN IF NOT EXISTS page_start INTEGER;
ALTER TABLE rag.document_chunks ADD COLUMN IF NOT EXISTS page_end INTEGER;
ALTER TABLE rag.document_chunks ADD COLUMN IF NOT EXISTS block_type TEXT;
COMMENT ON TABLE rag.document_chunks IS '원본 문서를 청킹한 텍스트와 임베딩 벡터를 저장하는 공용 Vector RAG 테이블';
COMMENT ON COLUMN rag.document_chunks.document_chunks_id IS '청크 고유 식별자';
COMMENT ON COLUMN rag.document_chunks.documents_id IS '청크가 생성된 원본 문서';
COMMENT ON COLUMN rag.document_chunks.chunk_index IS '원본 문서 내부의 청크 순서';
COMMENT ON COLUMN rag.document_chunks.page_number IS '페이지 기반 문서의 대표 원본 페이지 번호';
COMMENT ON COLUMN rag.document_chunks.page_start IS '청크 또는 블록이 시작되는 원본 페이지 번호';
COMMENT ON COLUMN rag.document_chunks.page_end IS '청크 또는 블록이 끝나는 원본 페이지 번호';
COMMENT ON COLUMN rag.document_chunks.block_type IS '공통 문서 블록 유형. 예: text, table, image';
COMMENT ON COLUMN rag.document_chunks.section_title IS '청크가 포함된 제목 또는 조항 제목';
COMMENT ON COLUMN rag.document_chunks.section_path IS '상위 제목을 포함한 계층형 문서 위치';
COMMENT ON COLUMN rag.document_chunks.chunk_text IS '검색 및 LLM 컨텍스트에 사용할 청크 본문';
COMMENT ON COLUMN rag.document_chunks.chunk_hash IS '청크 중복 및 변경 판단을 위한 해시값';
COMMENT ON COLUMN rag.document_chunks.embedding IS '검색용 임베딩 벡터';
COMMENT ON COLUMN rag.document_chunks.embedding_provider IS '임베딩 제공자';
COMMENT ON COLUMN rag.document_chunks.embedding_model IS '임베딩 생성에 사용한 모델';
COMMENT ON COLUMN rag.document_chunks.embedding_dimension IS '임베딩 벡터 차원';
COMMENT ON COLUMN rag.document_chunks.chunk_strategy IS '청킹 방식';
COMMENT ON COLUMN rag.document_chunks.chunk_size IS '청킹 시 사용한 최대 크기';
COMMENT ON COLUMN rag.document_chunks.chunk_overlap IS '인접 청크 중첩 크기';
COMMENT ON COLUMN rag.document_chunks.metadata IS '청크별 추가 속성';
COMMENT ON COLUMN rag.document_chunks.created_at IS '청크 생성 일시';
COMMENT ON COLUMN rag.document_chunks.updated_at IS '청크 최종 수정 일시';

CREATE TABLE IF NOT EXISTS rag.evaluation_cases (
    evaluation_cases_id BIGSERIAL PRIMARY KEY,
    evaluation_set_code TEXT NOT NULL,
    source_documents_id BIGINT REFERENCES rag.documents(documents_id),
    question TEXT NOT NULL,
    reference_answer TEXT,
    evaluator_notes TEXT,
    metadata JSONB,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE rag.evaluation_cases IS '검색 및 생성 품질 평가에 사용하는 평가 질문과 기준 답변을 관리하는 테이블';
COMMENT ON COLUMN rag.evaluation_cases.evaluation_cases_id IS '평가 문제 고유 식별자';
COMMENT ON COLUMN rag.evaluation_cases.evaluation_set_code IS '평가셋 그룹 코드';
COMMENT ON COLUMN rag.evaluation_cases.source_documents_id IS '평가 문제가 원본 데이터에서 생성된 경우 해당 원본 문서';
COMMENT ON COLUMN rag.evaluation_cases.question IS 'RAG 시스템에 입력할 평가 질문';
COMMENT ON COLUMN rag.evaluation_cases.reference_answer IS '생성답변 평가에 사용할 기준 답변 또는 기준 내용';
COMMENT ON COLUMN rag.evaluation_cases.evaluator_notes IS '평가자가 참고할 추가 설명';
COMMENT ON COLUMN rag.evaluation_cases.metadata IS '평가 건별 사용자 정의 속성';
COMMENT ON COLUMN rag.evaluation_cases.is_active IS '현재 평가에 사용할 평가 건인지 여부';
COMMENT ON COLUMN rag.evaluation_cases.created_at IS '평가 건 생성 일시';
COMMENT ON COLUMN rag.evaluation_cases.updated_at IS '평가 건 최종 수정 일시';

CREATE TABLE IF NOT EXISTS rag.evaluation_targets (
    evaluation_targets_id BIGSERIAL PRIMARY KEY,
    evaluation_cases_id BIGINT NOT NULL REFERENCES rag.evaluation_cases(evaluation_cases_id) ON DELETE CASCADE,
    collections_id BIGINT NOT NULL REFERENCES rag.collections(collections_id),
    target_code TEXT NOT NULL,
    target_name TEXT,
    top_k INTEGER NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(evaluation_cases_id, collections_id, target_code)
);
COMMENT ON TABLE rag.evaluation_targets IS '하나의 평가 질문에서 독립적으로 평가할 검색 컬렉션을 정의하는 테이블';
COMMENT ON COLUMN rag.evaluation_targets.evaluation_targets_id IS '평가 검색 대상 고유 식별자';
COMMENT ON COLUMN rag.evaluation_targets.evaluation_cases_id IS '연결된 평가 질문';
COMMENT ON COLUMN rag.evaluation_targets.collections_id IS '검색 성능을 평가할 컬렉션';
COMMENT ON COLUMN rag.evaluation_targets.target_code IS '평가 프로그램에서 사용할 검색 대상 코드';
COMMENT ON COLUMN rag.evaluation_targets.target_name IS '화면 표시용 검색 대상 이름';
COMMENT ON COLUMN rag.evaluation_targets.top_k IS '검색 평가 시 사용할 Top-K';
COMMENT ON COLUMN rag.evaluation_targets.created_at IS '평가 검색 대상 생성 일시';

CREATE TABLE IF NOT EXISTS rag.evaluation_expected_documents (
    evaluation_expected_documents_id BIGSERIAL PRIMARY KEY,
    evaluation_targets_id BIGINT NOT NULL REFERENCES rag.evaluation_targets(evaluation_targets_id) ON DELETE CASCADE,
    documents_id BIGINT NOT NULL REFERENCES rag.documents(documents_id),
    relevance_grade INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(evaluation_targets_id, documents_id)
);
COMMENT ON TABLE rag.evaluation_expected_documents IS '검색 평가 시 정답으로 간주하는 문서를 저장하는 Ground Truth 테이블';
COMMENT ON COLUMN rag.evaluation_expected_documents.evaluation_expected_documents_id IS '문서 Ground Truth 고유 식별자';
COMMENT ON COLUMN rag.evaluation_expected_documents.evaluation_targets_id IS '어떤 검색 평가 대상에 대한 정답인지 연결';
COMMENT ON COLUMN rag.evaluation_expected_documents.documents_id IS '정답으로 기대되는 문서';
COMMENT ON COLUMN rag.evaluation_expected_documents.relevance_grade IS '정답 문서의 관련성 등급';
COMMENT ON COLUMN rag.evaluation_expected_documents.notes IS '정답으로 선정한 이유 및 참고사항';
COMMENT ON COLUMN rag.evaluation_expected_documents.created_at IS '문서 Ground Truth 생성 일시';

CREATE TABLE IF NOT EXISTS rag.evaluation_expected_chunks (
    evaluation_expected_chunks_id BIGSERIAL PRIMARY KEY,
    evaluation_targets_id BIGINT NOT NULL REFERENCES rag.evaluation_targets(evaluation_targets_id) ON DELETE CASCADE,
    document_chunks_id BIGINT NOT NULL REFERENCES rag.document_chunks(document_chunks_id),
    relevance_grade INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(evaluation_targets_id, document_chunks_id)
);
COMMENT ON TABLE rag.evaluation_expected_chunks IS '관련 조항 또는 청크까지 찾았는지 평가하기 위한 Ground Truth';
COMMENT ON COLUMN rag.evaluation_expected_chunks.evaluation_expected_chunks_id IS '청크 Ground Truth 고유 식별자';
COMMENT ON COLUMN rag.evaluation_expected_chunks.evaluation_targets_id IS '검색 평가 대상';
COMMENT ON COLUMN rag.evaluation_expected_chunks.document_chunks_id IS '정답으로 기대되는 청크';
COMMENT ON COLUMN rag.evaluation_expected_chunks.relevance_grade IS '청크의 관련성 등급';
COMMENT ON COLUMN rag.evaluation_expected_chunks.notes IS '청크를 정답으로 선정한 이유 및 참고사항';
COMMENT ON COLUMN rag.evaluation_expected_chunks.created_at IS '청크 Ground Truth 생성 일시';

CREATE TABLE IF NOT EXISTS rag.evaluation_runs (
    evaluation_runs_id BIGSERIAL PRIMARY KEY,
    evaluation_set_code TEXT NOT NULL,
    run_name TEXT,
    embedding_provider TEXT,
    embedding_model TEXT,
    reranker_model TEXT,
    generator_provider TEXT,
    generator_model TEXT,
    evaluator_provider TEXT,
    evaluator_model TEXT,
    config JSONB,
    status TEXT NOT NULL DEFAULT 'RUNNING',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);
COMMENT ON TABLE rag.evaluation_runs IS '평가 실행 단위를 관리하고 실행 당시 모델 및 설정을 기록하는 테이블';
COMMENT ON COLUMN rag.evaluation_runs.evaluation_runs_id IS '평가 실행 고유 식별자';
COMMENT ON COLUMN rag.evaluation_runs.evaluation_set_code IS '실행에 사용한 평가셋';
COMMENT ON COLUMN rag.evaluation_runs.run_name IS '평가 실행을 구분하기 위한 사용자 지정 이름';
COMMENT ON COLUMN rag.evaluation_runs.embedding_provider IS '평가 당시 사용한 임베딩 제공자';
COMMENT ON COLUMN rag.evaluation_runs.embedding_model IS '평가 당시 사용한 임베딩 모델';
COMMENT ON COLUMN rag.evaluation_runs.reranker_model IS '평가 당시 사용한 Reranker 모델';
COMMENT ON COLUMN rag.evaluation_runs.generator_provider IS '답변 생성 LLM 제공자';
COMMENT ON COLUMN rag.evaluation_runs.generator_model IS '답변 생성 LLM 모델';
COMMENT ON COLUMN rag.evaluation_runs.evaluator_provider IS '생성 품질 평가 LLM 제공자';
COMMENT ON COLUMN rag.evaluation_runs.evaluator_model IS '생성 품질 평가 모델';
COMMENT ON COLUMN rag.evaluation_runs.config IS '평가 당시 전체 설정';
COMMENT ON COLUMN rag.evaluation_runs.status IS '평가 실행 상태';
COMMENT ON COLUMN rag.evaluation_runs.started_at IS '평가 시작 일시';
COMMENT ON COLUMN rag.evaluation_runs.completed_at IS '평가 완료 일시';

CREATE TABLE IF NOT EXISTS rag.retrieval_evaluation_results (
    retrieval_evaluation_results_id BIGSERIAL PRIMARY KEY,
    evaluation_runs_id BIGINT NOT NULL REFERENCES rag.evaluation_runs(evaluation_runs_id) ON DELETE CASCADE,
    evaluation_cases_id BIGINT NOT NULL REFERENCES rag.evaluation_cases(evaluation_cases_id),
    evaluation_targets_id BIGINT NOT NULL REFERENCES rag.evaluation_targets(evaluation_targets_id),
    recall_at_k DOUBLE PRECISION,
    precision_at_k DOUBLE PRECISION,
    mrr DOUBLE PRECISION,
    hit_count INTEGER,
    ground_truth_count INTEGER,
    retrieved_results JSONB,
    elapsed_ms DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(evaluation_runs_id, evaluation_cases_id, evaluation_targets_id)
);
COMMENT ON TABLE rag.retrieval_evaluation_results IS '각 평가 질문과 검색 컬렉션별 검색 품질 결과';
COMMENT ON COLUMN rag.retrieval_evaluation_results.retrieval_evaluation_results_id IS '검색 평가 결과 고유 식별자';
COMMENT ON COLUMN rag.retrieval_evaluation_results.evaluation_runs_id IS '평가 실행 식별자';
COMMENT ON COLUMN rag.retrieval_evaluation_results.evaluation_cases_id IS '평가 질문';
COMMENT ON COLUMN rag.retrieval_evaluation_results.evaluation_targets_id IS '평가한 검색 컬렉션';
COMMENT ON COLUMN rag.retrieval_evaluation_results.recall_at_k IS 'Ground Truth 중 Top-K 검색 결과에 포함된 비율';
COMMENT ON COLUMN rag.retrieval_evaluation_results.precision_at_k IS 'Top-K 검색 결과 중 Ground Truth에 해당하는 비율';
COMMENT ON COLUMN rag.retrieval_evaluation_results.mrr IS '첫 번째 정답 문서의 순위를 반영한 MRR';
COMMENT ON COLUMN rag.retrieval_evaluation_results.hit_count IS '검색 결과에서 실제 적중한 Ground Truth 수';
COMMENT ON COLUMN rag.retrieval_evaluation_results.ground_truth_count IS '해당 평가 건의 전체 Ground Truth 수';
COMMENT ON COLUMN rag.retrieval_evaluation_results.retrieved_results IS '검색된 문서, 청크, 점수, 순위 등의 상세 결과';
COMMENT ON COLUMN rag.retrieval_evaluation_results.elapsed_ms IS '검색 및 평가에 소요된 시간';
COMMENT ON COLUMN rag.retrieval_evaluation_results.created_at IS '검색 평가 결과 생성 일시';

CREATE TABLE IF NOT EXISTS rag.generation_evaluation_results (
    generation_evaluation_results_id BIGSERIAL PRIMARY KEY,
    evaluation_runs_id BIGINT NOT NULL REFERENCES rag.evaluation_runs(evaluation_runs_id) ON DELETE CASCADE,
    evaluation_cases_id BIGINT NOT NULL REFERENCES rag.evaluation_cases(evaluation_cases_id),
    generated_answer TEXT NOT NULL,
    relevance_score DOUBLE PRECISION,
    factuality_score DOUBLE PRECISION,
    groundedness_score DOUBLE PRECISION,
    specificity_score DOUBLE PRECISION,
    actionability_score DOUBLE PRECISION,
    cause_alignment_score DOUBLE PRECISION,
    evidence_alignment_score DOUBLE PRECISION,
    total_score DOUBLE PRECISION,
    evaluator_reason TEXT,
    evaluator_detail JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(evaluation_runs_id, evaluation_cases_id)
);
COMMENT ON TABLE rag.generation_evaluation_results IS '검색된 근거를 이용해 생성한 최종 답변의 품질 평가 결과';
COMMENT ON COLUMN rag.generation_evaluation_results.generation_evaluation_results_id IS '생성 평가 결과 고유 식별자';
COMMENT ON COLUMN rag.generation_evaluation_results.evaluation_runs_id IS '평가 실행 식별자';
COMMENT ON COLUMN rag.generation_evaluation_results.evaluation_cases_id IS '평가 질문';
COMMENT ON COLUMN rag.generation_evaluation_results.generated_answer IS 'RAG 시스템이 생성한 최종 답변';
COMMENT ON COLUMN rag.generation_evaluation_results.relevance_score IS '질문과 생성 답변의 관련성 평가 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.factuality_score IS '생성 답변의 사실성 평가 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.groundedness_score IS '검색된 근거 밖의 내용을 임의로 생성하지 않았는지 평가하는 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.specificity_score IS '답변이 충분히 구체적인지 평가하는 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.actionability_score IS '답변 내용을 실제 업무에서 실행할 수 있는지 평가하는 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.cause_alignment_score IS '입력의 문제 또는 원인에 적절하게 대응하는지 평가하는 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.evidence_alignment_score IS '검색된 근거 문서와 답변 내용이 일치하는지 평가하는 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.total_score IS '개별 평가 항목을 가중 계산한 최종 점수';
COMMENT ON COLUMN rag.generation_evaluation_results.evaluator_reason IS '평가 모델 또는 평가자가 작성한 점수 산정 이유';
COMMENT ON COLUMN rag.generation_evaluation_results.evaluator_detail IS '항목별 판단 근거 및 추가 평가 데이터';
COMMENT ON COLUMN rag.generation_evaluation_results.created_at IS '평가 결과 생성 일시';

CREATE INDEX IF NOT EXISTS idx_documents_collection ON rag.documents(collections_id);
CREATE INDEX IF NOT EXISTS idx_documents_evaluation ON rag.documents(is_evaluation);
CREATE INDEX IF NOT EXISTS idx_documents_evaluation_set ON rag.documents(evaluation_set_code);
CREATE INDEX IF NOT EXISTS idx_documents_active ON rag.documents(is_active);
CREATE INDEX IF NOT EXISTS idx_documents_source_hash ON rag.documents(source_hash);
CREATE UNIQUE INDEX IF NOT EXISTS uq_document_chunks_hash ON rag.document_chunks(chunk_hash);
CREATE INDEX IF NOT EXISTS idx_document_chunks_document ON rag.document_chunks(documents_id);
CREATE INDEX IF NOT EXISTS idx_document_chunks_embedding_hnsw ON rag.document_chunks USING hnsw (embedding vector_cosine_ops);

-- ============================================================
-- 생성 Notebook 전용 영속 Vector 색인 메타데이터
-- 아래 템플릿 값은 Notebook이 실행 시 안전한 생성값으로 치환함
-- ============================================================

CREATE TABLE IF NOT EXISTS {{PGVECTOR_META_TABLE}}
(
    namespace       TEXT PRIMARY KEY,
    manifest        JSONB NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE {{PGVECTOR_META_TABLE}} IS
'생성 Notebook별 pgvector 색인의 청킹·임베딩 설정을 기록하여 호환성과 재사용 여부를 판단하는 메타데이터 테이블';

COMMENT ON COLUMN {{PGVECTOR_META_TABLE}}.namespace IS
'생성 Notebook의 pgvector 색인을 구분하는 고유 네임스페이스';

COMMENT ON COLUMN {{PGVECTOR_META_TABLE}}.manifest IS
'청킹 설정, 임베딩 모델·차원, 컬렉션 설정 등 색인 호환성 판단 정보';

COMMENT ON COLUMN {{PGVECTOR_META_TABLE}}.updated_at IS
'색인 메타데이터 최종 갱신 일시';


CREATE TABLE IF NOT EXISTS {{PGVECTOR_SOURCE_TABLE}}
(
    source_versions_id BIGSERIAL PRIMARY KEY,
    namespace          TEXT NOT NULL,
    collection_code    TEXT NOT NULL,
    source_key         TEXT NOT NULL,
    source_name        TEXT NOT NULL,
    source_hash        TEXT NOT NULL,
    document_version   INTEGER NOT NULL DEFAULT 1,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    metadata           JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    superseded_at      TIMESTAMPTZ
);

COMMENT ON TABLE {{PGVECTOR_SOURCE_TABLE}} IS
'원본 파일 또는 구조화 레코드의 해시와 문서 버전을 보존하여 신규·동일·변경 데이터를 증분 판정하는 테이블';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.source_versions_id IS
'원본 버전 고유 식별자';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.namespace IS
'생성 Notebook의 pgvector 색인 네임스페이스';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.collection_code IS
'원본이 속한 사용자 정의 RAG 컬렉션 코드';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.source_key IS
'원본 파일 또는 구조화 레코드를 안정적으로 식별하는 논리 키';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.source_name IS
'사용자에게 표시할 원본 파일명 또는 데이터 소스 이름';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.source_hash IS
'원본 내용 변경 여부를 판정하는 SHA-256 해시';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.document_version IS
'동일 source_key에서 원본 내용이 변경될 때 1씩 증가하는 문서 버전';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.is_active IS
'현재 검색에 사용할 최신 문서 버전 여부';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.metadata IS
'원본 유형, 상대 경로, 행 번호 등 확장 메타데이터';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.created_at IS
'해당 원본 버전 등록 일시';
COMMENT ON COLUMN {{PGVECTOR_SOURCE_TABLE}}.superseded_at IS
'새 버전으로 교체되어 비활성화된 일시';

CREATE UNIQUE INDEX IF NOT EXISTS {{PGVECTOR_SOURCE_ACTIVE_INDEX}}
ON {{PGVECTOR_SOURCE_TABLE}} (namespace, collection_code, source_key)
WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS {{PGVECTOR_SOURCE_LOOKUP_INDEX}}
ON {{PGVECTOR_SOURCE_TABLE}} (namespace, collection_code, source_key, document_version DESC);


CREATE TABLE IF NOT EXISTS {{PGVECTOR_TABLE}}
(
    document_key       TEXT PRIMARY KEY,
    source_versions_id BIGINT NOT NULL REFERENCES {{PGVECTOR_SOURCE_TABLE}}(source_versions_id),
    collection_code    TEXT NOT NULL,
    source_name        TEXT NOT NULL,
    chunk_hash         TEXT NOT NULL,
    content            TEXT NOT NULL,
    metadata           JSONB NOT NULL DEFAULT '{}'::jsonb,
    embedding          VECTOR({{VECTOR_DIMENSION}}) NOT NULL,
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE {{PGVECTOR_TABLE}} IS
'생성 Notebook이 사용하는 영속 RAG 청크 및 임베딩 벡터 저장 테이블. 이전 문서 버전의 청크도 보존한다.';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.document_key IS
'원본 버전 ID와 청크 해시를 조합한 청크 고유 키';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.source_versions_id IS
'이 청크가 속한 원본 문서 버전 식별자';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.collection_code IS
'청크가 속한 사용자 정의 RAG 컬렉션 코드';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.source_name IS
'원본 파일 또는 데이터 소스 이름';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.chunk_hash IS
'청크 본문과 메타데이터로 계산한 SHA-256 해시';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.content IS
'RAG 검색에 사용하는 청크 본문';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.metadata IS
'원본 위치, 페이지, 행 번호 등 청크의 추가 속성';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.embedding IS
'선택한 임베딩 모델로 생성한 검색용 벡터';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.is_active IS
'현재 활성 문서 버전에 속한 검색 대상 청크 여부';
COMMENT ON COLUMN {{PGVECTOR_TABLE}}.created_at IS
'벡터 청크 최초 저장 일시';

CREATE INDEX IF NOT EXISTS {{PGVECTOR_CHUNK_ACTIVE_INDEX}}
ON {{PGVECTOR_TABLE}} (is_active, source_versions_id);

